package Catalyst::View::XSLT;

use strict;
use warnings;
use base 'Catalyst::View';
use Catalyst::View::XSLT::XML::LibXSLT;
use Data::Dumper;
use File::Spec;

our $VERSION = '0.09';

# check if this is a MS Windows 
my $isMS = $^O eq 'MSWin32';

=head1 NAME

Catalyst::View::XSLT - XSLT View Class

=head1 SYNOPSIS

    # use the helper to create your view
    myapp_create.pl view XSLT XSLT

    # configure in lib/MyApp/View/XSLT.pm (can be done from a config file too)
    package MyApp::View::XSLT;

    use base 'Catalyst::View::XSLT';

    __PACKAGE__->config(
        # paths to the directories with templates
        INCLUDE_PATH => [
          MyApp->path_to( 'root', 'xslt' ),
          MyApp->path_to( 'templates', 'xsl' ),
        ],

        # default template extension to use
        # when you don't provide template name
        TEMPLATE_EXTENSION => '.xsl',

        # use this for debug purposes
        # it will dump the the final (merged) config
        DUMP_CONFIG => 1,

        # XML::LibXSLT specific configuration 
        LibXSLT => {
            register_function => [
              {
                uri    => 'urn:catalyst',
                name   => 'add',
                subref => sub { return $_[0] + $_[1] },
              },
              {
                uri    => 'urn:foo',
                name   => 'Hello',
                subref => sub { return 'Hello, Catalyst\'s user.' },
              },
            ],
        },
    );

    # don't need nothing more

    1;

    # in your controller(s) :
    sub someAction : Local {

        # 'template' could be string or path to file
        # see 'xml' for more info about string version 

        # path to the template could be absolute
        $c->stash->{template} = $c->config->{home} . 'root/some.xsl';

        # or relative
        $c->stash->{template} = 'some.xsl'; # this file will be searched in include paths

        # or if you didn't provide any template name 
        # then the last chance is 'someAction.xsl' ($c->action . $config->{TEMPLATE_EXTENSION})

        # 'xml' could be string
        $c->stash->{xml} =<<XML;
<root>
  <level1>data</level>
</root>
XML
        # or a relative path which will se searched in include paths
        # $c->stash->{xml} = 'my.xml';

        # or an absolute path 
        # $c->stash->{xml} = '/some/where/around.xml';

        # add more subrefs (these will predefine config ones if they overlap)
        $c->stash->{additional_register_function} = [
          {
            uri => 'urn:catalyst',
            name => 'doIt',
            subref => sub { return $obj->method(@_) },
          }
        ];

        # everything else in the stash will be used for parameters (<xsl:param name="param1" />)
        $c->stash->{param1} = 'Param1 value';'
        $c->stash->{param2} = 'Param2 value';
    }

    # Meanwhile, maybe in an 'end' action

    $c->forward('MyApp::View::XSLT');

    # to use your registered functions in some.xsl:
    <xsl:stylesheet 
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:catalyst="urn:catalyst"
      xmlns:foo="urn:foo"
      version="1.0">
      ...
      <xsl:value-of select="catalyst:add(4, 5)" />
      <xsl:value-of select="foo:Hello()" />
      <xsl:value-of select="catalyst:doIt($param1, 3)" />
      ...
    </xsl:stylesheet>

=head1 DESCRIPTION

This is a C<XSLT> view class for Catalyst.
Your application should defined a view class which is a subclass of
this module.  The easiest way to achieve this is using the
F<myapp_create.pl> script (where F<myapp> should be replaced with
whatever your application is called).  This script is created as part
of the Catalyst setup.

=head1 METHODS

=over 4

=item new

The constructor for the XSLT view. 
Reads the application config.

=cut

# this code is borrowed from Catalyst::View::TT
sub _coerce_paths {
    my ( $paths, $dlim ) = shift;
    return () if ( !$paths );
    return @{$paths} if ( ref $paths eq 'ARRAY' );

    # tweak delim to ignore C:/
    unless ( defined $dlim ) {
        $dlim = ( $isMS ) ? ':(?!\\/)' : ':';
    }
    return split( /$dlim/, $paths );
}


sub new {
    my ($proto, $c) = @_;

    my $class = ref $proto || $proto;

    # default configuration
    my $config = {
        # DEFAULT VALUES

        # this the default internal implementation
        # can be overwritten in application or class config
        PROCESSOR => 'Catalyst::View::XSLT::XML::LibXSLT',

        # default file extension for xslt files
        TEMPLATE_EXTENSION => '.xsl',

        # don't dump XSLT view config by default
        DUMP_CONFIG => 0,

        # DEFAULT VALUES END


        # global app config
        %{ $c->config->{'View::XSLT'} || {} },
        %{ $c->config->{'V::XSLT'} || {} },

        # class' config has precedence
        %{ $class->config() || {} },
    };


    if ( ! (ref $config->{INCLUDE_PATH} eq 'ARRAY') ) {
        my $delim = $config->{DELIMITER};
        my @include_path
            = _coerce_paths( $config->{INCLUDE_PATH}, $delim );
        if ( !@include_path ) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir( $root, 'base' );
            @include_path = ( "$root", "$base" );
        }
        $config->{INCLUDE_PATH} = \@include_path;
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        $c->log->debug( 'XSLT Config: ', Dumper($config) );
    }

    my $self = {};

    bless($self, $class);

    $self->{CONFIG} = $config;

    return $self;
}

=item render

Renders the template specified via C<< $template >>.
The template parameters are set to C<%$args> if $args is a hashref, or 
C<< $c->stash >> otherwise.

Templates are accepted as strings, filehandles or objects of the corresponding
view types (L<XML::LibXML::Document> for example).

=cut

sub render {
    my ( $self, $c, $template, $args ) = @_;
    my $basePath;

    unless ( $template =~ m/\</ || (ref($template) && $template->isa('GLOB')) || -e $template ||
      ( ref($template) && !$template->isa('Path::Class::File') ) ) {
        my $error;

        ($basePath, $error) = $self->_searchInIncPath($c, $template);

        if (defined $error) {
            $c->error("Template [$template] does not exists in include path");
            return 0;
        } else {
            $template = File::Spec->catfile($basePath, $template);
        }
    }

    unless ($basePath) {
        $basePath = $c->config->{root};
    }

    my $vars = { 
        (ref $args eq 'HASH' ? %$args : %{ $c->stash() }),
    };

    unless (exists $vars->{ xml } && defined $vars->{ xml }) {
        $c->log->error( 'No xml provided' );
        return undef;
    }

    my $xml = $vars->{xml};

    # if xml is not string (therefore is a file (what about file descriptors ?!)) 
    # and is not existsting in the file system
    unless ( $xml =~ m/\</ || (ref($template) && $xml->isa('GLOB')) || -e $xml ||
      ( ref($xml) && !$xml->isa('Path::Class::File') ) ) {
        my ($incPath, $error) = $self->_searchInIncPath($c, $xml);

        if (defined $error) {
            $c->error("XML file [$xml] does not exists in include path");
            return undef;
        } else {
            $vars->{xml} = File::Spec->catfile($incPath, $xml);
        }
    }

    $c->log->debug( qq{Rendering template "$template"} ) if $c->debug;

    # add runtime register_function(s) from stash
    if (exists $vars->{additional_register_function} &&
      ref($vars->{additional_register_function}) eq 'ARRAY' ) {
        my @additional_subrefs = @{ $vars->{additional_register_function} };
        delete $vars->{additional_register_function};

        unless (ref($self->{CONFIG}->{LibXSLT}->{register_function}) eq 'ARRAY') {
            $self->{CONFIG}->{LibXSLT}->{register_function} = [];
        }

        unshift(
          @{ $self->{CONFIG}->{LibXSLT}->{register_function} }, 
          @additional_subrefs
        );
    }

    my $processor = undef;
    eval {
        $processor = $self->_getProcessor()->new($c, $self->{CONFIG}->{LibXSLT});		
    };

    if ($@ && (! defined $processor)) {
        $c->error("Could not instanciate XSLT processor: $@");
        return undef;
    } elsif (scalar @{$c->error}) {
        return undef;
    }

    $c->log->debug("Processing...") if $c->debug;
    my ($output, $error) = $processor->process($template, $vars, $basePath);

    if ($error) {
        chomp $error;
        $error = qq{Couldn't render template "$template". Error: "$error"};
        $c->error($error);
        return undef;
    } 
    else {
        return $output;
    }
}

=item process

Renders the template specified in C<< $c->stash->{template} >> or C<<
$c->action >>.  Calls C<< render >> to perform actual rendering.
Template params are set up from the contents of C<< $c->stash >>.
Output is stored in C<< $c->response->body >>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = undef;

    if (exists $c->stash->{template} && defined $c->stash->{template}) {
    	$template = delete $c->stash->{template};
    } else {
    	my $actionName = $c->action;
    	my $ext = $self->{CONFIG}->{'TEMPLATE_EXTENSION'};

        $template = $actionName . $ext;
    	$c->log->debug( "Going to create template name from the action name and default extension: [$template]" ) if $c->debug;
    }

    unless ($template) {
    	# probably this will never happen, but for any case
        $c->log->error( 'No template specified for rendering' );
        return 0;
    }

    my $output = $self->render($c, $template);

    $c->response->body($output);

    return 1;
}

# INTERNAL METHODS

# returns the current set internal processor
sub _getProcessor {
    my ($self) = @_;

    return $self->{CONFIG}->{PROCESSOR};
}

# searchs for a file ($filename) in INCLUDE_PATH
# returns the first occurence
sub _searchInIncPath {
    my ($self, $c, $filename) = @_;

    $c->log->debug( "searching in include path for [$filename]") if $c->debug;

    my $arefIncludePath = $self->{CONFIG}->{'INCLUDE_PATH'};

    if (ref $c->stash->{additional_template_paths} eq 'ARRAY') {
        unshift( @{ $arefIncludePath },
          @{ $c->stash->{additional_template_paths} } );
    }

    foreach my $incEntry ( @{ $arefIncludePath} ) {

        $c->log->debug( "Going to search for file [$filename] in [$incEntry]" ) if $c->debug;
        my $tmpTemplateName = '';
        my $incPath = '';

        if (ref $incEntry eq 'Path::Class::File') {
            $incPath = $incEntry->absolute();
        } else {
            $incPath = $incEntry;
        }

        if (-e File::Spec->catfile($incPath, $filename)) {

            $c->log->debug( "File [$filename] found in [$incEntry]") if $c->debug;
            return ($incPath, undef);
        }

    }

    return (undef, 1);	
}

=back

=head1 NOTE

This version works only with L<XML::LibXSLT>.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Base>, L<XML::LibXSLT>

=head1 AUTHORS

Martin Grigorov, E<lt>mcgregory {at} e-card {dot} bgE<gt>

Simon Bertrang, E<lt>simon.bertrang@puzzworks.comE<gt>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
