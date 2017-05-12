use strict;
use warnings;

package Config::TT2;

use Template;
use Try::Tiny;
use Carp qw(croak);

our $VERSION = '0.53';

=head1 NAME

Config::TT2 - Reading configuration files with the Template-Toolkit parser.

=head1 ABSTRACT

Define configuration files in the powerful, flexible and extensible Template-Toolkit syntax.

=cut

sub new {
    my $class = shift;

    # params as HASH or HASHREF?
    my $params = defined( $_[0] ) && ref( $_[0] ) eq 'HASH' ? shift : {@_};

    #
    # Warn for unsupported Template and Template::Service params.
    # Our entry level is Template::Context, see Template::Manual::Internals
    #
    my @unsupported = qw(
      PRE_PROCESS
      PROCESS
      POST_PROCESS
      WRAPPER
      AUTO_RESET
      DEFAULT
      OUTPUT
      OUTPUT_PATH
      ERROR
      ERRORS
    );

    foreach my $unsupported (@unsupported) {
        croak "Option '$unsupported' not supported\n"
          if exists $params->{$unsupported};
    }

    #
    # DEFAULTS, see Template::Manual::Config
    #
    my $defaults = {
        STRICT     => 1,
        ABSOLUTE   => 1,
        RELATIVE   => 1,
        CACHE_SIZE => 0,
    };

    # override defaults by params
    my $self = bless { _PARAMS => { %$defaults, %$params } }, $class;

    my $tt = Template->new( $self->{_PARAMS} ) || croak "$Template::ERROR\n";

    # our entry level into TT2 is Template::Context to get the stash back
    $self->context( $tt->service->context );

    return $self;
}

sub context {
    my ( $self, $ctx ) = @_;
    $self->{_CONTEXT} = $ctx if defined $ctx;
    return $self->{_CONTEXT};
}

sub process {
    my ( $self, $template, $vars ) = @_;

    my $ctx   = $self->context;
    my $stash = $ctx->stash;

    #
    # processing template from Template::Context level and NOT
    # from Template::Service level to get the stash back
    #
    my ( $output, $error );
    try {
        my $comp_template = $ctx->template($template);

        # play Template::Service, preset template slot
        $vars->{template} = $comp_template;

        # ok, process at Template::Context level
        $output = $ctx->process( $comp_template, $vars );
    }
    catch { $error = $_ };
    croak "$error" if $error;

    # remove initial stash keys like _STRICT, _DEBUG, inc, ...
    $self->_purge_stash;

    return wantarray ? ( $ctx->stash, $output ) : $ctx->stash;
}

sub _purge_stash {
    my $self = shift;

    my @purge_keys = qw(
      template
      component
      inc
      dec
      _PARENT
      _STRICT
      _DEBUG
    );

    my $stash = $self->context->stash;

    if ( $stash->{_DEBUG} ) {
        my $pkg = __PACKAGE__;

        warn "[${pkg}::_purge_stash] purging keys:\n";
        warn join( ', ', @purge_keys ) . "\n";
    }

    foreach my $key (@purge_keys) {

        #
        # initial root VMethods inc, dec
        #
        if ( $key eq 'inc' || $key eq 'dec' ) {
            delete $stash->{$key} if ref $stash->{$key} eq 'CODE';
            next;
        }

        delete $stash->{$key};
    }
}

=head1 SYNOPSIS

    use Config::TT2;

    my $ctt2      = Config::TT2->new;
    my $cfg_stash = $ctt2->process($file);

=head1 DESCRIPTION

C<< Config::TT2 >> extends the C<< Template-Toolkit >> aka C<< TT2 >> in a very special way:

It returns the B<< VARIABLES STASH >> instead of the template text!

The TT2 syntax is very powerful, flexible and extensible. One of the key features of TT2 is the ability to bind template variables to any kind of Perl data: scalars, lists, hash arrays, sub-routines and objects.

See L<< Template::Manual::Variables >> for a reference.

E.g. this Template-Toolkit config 

  [%                        # tt2 directive start-tag
    scalar = 'string'       # strings in single or double quotes

    array = [ 10 20 30 ]    # commas are optional
    rev   = array.reverse   # powerful virtual methods
    item  = array.0         # interpolate previous value

    hash = { foo = 'bar'    # hashes to any depth
             moo = array    # points to above arrayref
	   }
  %]                        # tt2 directive end-tag

is returned as a perl datastructure:

   'scalar' => 'string'
   'array' => ARRAY(0x8ad2708)
      0  10
      1  20
      2  30
   'rev' => ARRAY(0x8afe740)
      0  30
      1  20
      2  10
   'item' => 10
   'hash' => HASH(0x8afe160)
      'foo' => 'bar'
      'moo' => ARRAY(0x8ad2708)
         -> REUSED_ADDRESS

=head1 METHODS

=head2 new(%config)

The C<< new() >> constructor method instantiates a new C<Config::TT2> object. This method croaks on error.

Configuration items may be passed as a list of items or a hash array:

    my $ctt2 = Config::TT2->new(
        ABSOLUTE => 0,
        DEBUG    => 'all',
    );

The supported configuration options are the same as for C<< Template >>, please see the L<< Template::Manual::Config >> as a reference and the LIMITATIONS section below.

The preset default options which differ from the Template default options are:

  STRICT     = 1   # undefined vars or values cause exceptions
  ABSOLUTE   = 1   # files with absolute filenames allowed
  RELATIVE   = 1   # files with relative filenames allowed
  CACHE_SIZE = 0   # don't cache compiled config files

=head2 process($config, $variables)

The C<< process() >> method is called to process a config file or string. The first parameter indicates the input as one of: a filename; a reference to a text string containing the config text; or a file handle reference, from which the config can be read.

A reference to a hash array may be passed as the second parameter, containing definitions of input variables.

    $stash = $ctt2->process( '.app.cfg', {foo => $ENV{APP_FOO}} );

The returned datastructure is a C<< Template::Stash >> object. You may access the key and values through normal perl dereferencing:

   $item = $stash->{hash}{moo}[0];

or via the C<< Template::Stash->get >> method like:

   $item = $stash->get('hash.moo.0');

For debugging purposes you can even request the template output from the process method:

  ($stash, $output) = $ctt2->process( $config );

The method croaks on error.

=head1 LIMITATIONS

The Template-Toolkit processor uses the toplevel variables C<< template >> und C<< component >> for meta information during template file processing. You B<< MUST NOT >> define or redefine these toplevel variables at object creation, processing or within the config files.

See the section L<< Template::Manual::Variables/Special Variables >>.

The C<< process >> method purges these toplevel variables unconditionally after processing but before returning the stash.

See also the special meaning of the C<< global >> toplevel variable.

Successive calls to C<< process >> with the same Config::TT2 instance B<< MUST >> be avoided. The Template CONTEXT and STASH have states belonging to the processed config text. Create new instances for successive C<< process >> calls.

   $stash1 = Config::TT2->new->process($file1);
   $stash2 = Config::TT2->new->process($file2);

The following Template options are not supported with Config::TT2:

      PRE_PROCESS
      PROCESS
      POST_PROCESS
      WRAPPER
      AUTO_RESET
      DEFAULT
      OUTPUT
      OUTPUT_PATH
      ERROR
      ERRORS

=head1 EXTENSIONS AND VIRTUAL METHODS

With the C<< context >> method you can get/set the underlying Template::Context object.

=head2 context()

Getter/setter method for the underlying Template::Context object.

With the context you can also access the stash and define new virtual methods BEFORE processing.

    $ctt2 = Config::TT2->new;
    $ctt2->context->stash->define_vmethod( $type, $name, $code_ref );
    $cfg_stash = $ctt2->process($cfg_file);

See the manuals L<< Template::Stash >>, L<< Template::Context >> and L<< Template::Manual::Internals >>.

=head1 SEE ALSO

L<< Config::Any::TT2 >>, the corresponding L<< Config::Any >> plugin.

L<< Template::Manual::Intro >>, L<< Template::Manual::Syntax >>, L<< Template::Manual::Config >>, L<< Template::Manual::Variables >>, L<< Template::Manual::VMethods >>

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-tt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-TT2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::TT2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-TT2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-TT2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-TT2>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-TT2/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Karl Gaissmaier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Config::TT2

# vim: sw=4
