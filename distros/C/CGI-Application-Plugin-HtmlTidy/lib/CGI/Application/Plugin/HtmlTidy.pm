package CGI::Application::Plugin::HtmlTidy;
BEGIN {
  $CGI::Application::Plugin::HtmlTidy::VERSION = '1.05';
}

use 5.006;
use strict;
use warnings;
use Carp;
use CGI::Application 4.01;
use HTML::Template;
use HTML::Tidy 1.08;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(htmltidy htmltidy_clean htmltidy_config);

sub import
{
    my $c = scalar caller;
    $c->add_callback( 'devpopup_report', \&htmltidy_validate ) if $c->can('devpopup');
    goto &Exporter::import;
}

sub htmltidy
{
    my $self = shift;
    my $opts = $self->param('htmltidy_config') || {};
    htmltidy_config( $self, %$opts ) unless $self->{ __PACKAGE__ . 'OPTIONS' };
    $self->{ __PACKAGE__ . 'HTMLTIDY' } ||= HTML::Tidy->new( $self->{ __PACKAGE__ . 'OPTIONS' } );
}

sub htmltidy_config
{
    my $self = shift;
    my %opts = @_;

    # if no options are supplied, use the default config file.
    # otherwise, all options are passed through (and expected to be
    # valid tidy-options).
    if( !%opts ) {
        $opts{config_file} = __find_config();
    }
    
    $self->{ __PACKAGE__ . 'OPTIONS' } = \%opts;
}

sub htmltidy_clean
{
    my ( $self, $outputref ) = @_;
    return unless __check_header($self);
    $$outputref = $self->htmltidy->clean($$outputref);
}

sub htmltidy_validate
{
    my ( $self, $outputref ) = @_;
    return unless __check_header($self);
    $self->htmltidy->parse( 'why would i need to pass a file name if it isn\'t used?', $$outputref );
    if ( $self->htmltidy->messages )
    {
        my @msgs;
        my @output = map { { html => $_ } } split $/, $$outputref;
        my ($errors, $warnings) = (0,0);
        foreach ( $self->htmltidy->messages() )
        {
            $_->type == TIDY_WARNING ? $warnings++ : $errors++;
            push @{ $output[ $_->line - 1 ]->{messages} },
              {
                type => $_->type == TIDY_WARNING ? 'warning' : 'error',
                line => $_->line,
                column => $_->column,
                text   => $_->text,
              };
        }
        my $t = HTML::Template->new( filename => __find_my_path() . '/validate.tmpl', die_on_bad_params => 0, cache => 1 );
        $t->param( output => \@output );
        $self->devpopup->add_report(
            title   => 'HTML::Tidy validation report',
            summary => "$errors errors, $warnings warnings",
            report  => $t->output
        );
    }
    else
    {
        $self->devpopup->add_report(
            title   => 'HTML::Tidy validation report',
            summary => "Your HTML is valid!",
        );
    }
}

sub __check_header
{
    my $self = shift;

    return unless $self->header_type eq 'header';    # don't operate on redirects or 'none'

    my %props = $self->header_props;
    my ($type) = grep /type/i, keys %props;

    return 1 unless defined $type;                   # no type defaults to html, so we have work to do

    return $props{$type} =~ /html/i;
}

### find the config file
### 1. see if we can find the package version
### 2. fall back to /etc/tidy.conf
sub __find_config
{
    my $inc = __find_my_path() . '/tidy.conf';
    return -f $inc ? $inc : '/etc/tidy.conf';
}

sub __find_my_path
{
    my $inc = $INC{'CGI/Application/Plugin/HtmlTidy.pm'};
    $inc =~ s/\.pm$//;
    return $inc;
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::HtmlTidy - Add HTML::Tidy support to CGI::Application

=head1 VERSION

version 1.05

=head1 SYNOPSIS

  use CGI::Application::Plugin::HtmlTidy;
  
  sub cgiapp_postrun {
    my ($self, $contentref) = @_;

	# your post-process code here
	
    $self->htmltidy_clean($contentref);
  }

  
  # generate a validation report
  use CGI::Application::Plugin::DevPopup;
  use CGI::Application::Plugin::HtmlTidy;

=head1 CHANGES

This release integrates with L<CGI::Application::Plugin::DevPopup>. If that 
plugin is active, this one will add an HTML validation report. As a consequence,
htmltidy_validate() is no longer exported, and should not be called directly.

=head1 DESCRIPTION

This plugin is a wrapper around L<HTML::Tidy>. It exports two methods that
allow you to either validate or clean up the output of your cgiapp application.
They should be called at the end of your postrun method. 

The htmltidy_validate method is a helpful addition during development.
It generates a detailed report specifying the issues with your html.

The htmltidy_clean modifies your output to conform to the W3C standards.
It has been in use for quite some time on a largish site (generating
over 10 million pages per day) and has proven to be quite stable and fast.
Every single page view is valid html, which makes many browsers happy :-)

=head2 CONFIGURATION

libtidy is extremely configurable. It has many options to influence how
it transforms your documents. HTML::Tidy communicates these options to
libtidy through a configuration file. In the future, it may also allow
programmatic access to all options.

You can specify the configuration using cgiapp's param() method, or in your
instance script through the PARAM attribute, or through the htmltidy_config()
method. This plugin looks for a parameter named htmltidy_config, whose value
should be a hash ref.  This hash ref is then passed on directly to HTML::Tidy.
Currently the only supported parameter is "config_file".

Here's an example:

  sub setup {
    my $self = shift;
	$self->param( htmltidy_config => {
			    config_file => '/path/to/my/tidy.conf',
			});
  }

This plugin comes with a default configuration file with the following
settings:

	tidy-mark:      no
	wrap:           120
	indent:         auto
	output-xhtml:   yes
	char-encoding:  utf8
	doctype:        loose
	add-xml-decl:   yes
	alt-text:       [image]

=head2 EXPORT

=over 4

=item htmltidy

Direct access to the underlying HTML::Tidy object.

=item htmltidy_config

Pass in a hash of options to configure the behaviour of this plugin. Accepted
keys are:

=over 8

=item config_file

The path to a config file used by tidy. See the tidy man page for details.

=item tidy config options

HTML::Tidy 1.08 now supports tidy options directly, so there is no need for
a separate config file anymore. 

=back

=item htmltidy_validate

If you're using L<CGI::Application::Plugin::DevPopup>, this method is used to
generate a report for it.It parses your output, and generates a detailed
report if it doesn't conform to standards. 

=item htmltidy_clean

Parses and cleans your output to conform to standards.

=back

=head1 SEE ALSO

L<CGI::Application>, L<HTML::Tidy>.

The cgiapp mailing list can be used for questions, comments and reports.
The CPAN RT system can also be used.

=head1 AUTHOR

Rhesa Rozendaal, E<lt>rhesa@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Rhesa Rozendaal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut