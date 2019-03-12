#!/usr/bin/env perl

# This script gets pod of Data::Frame into Alt::Data::Frame::ButMore

use 5.016;
use warnings;

use Path::Tiny;
use Pod::POM 2.01;
use Pod::POM::View::Pod;
use Pod::Markdown::Github;

my ($distdir) = @ARGV;

package Pod::POM::View::Pod::SLOYD {
    use parent qw(Pod::POM::View::Pod);

    sub view_head1 {
        my ( $self, $head1 ) = @_;

        if ( $head1->title eq 'NAME' ) {
            my ( $self, $head1 ) = @_;
            return
                '=head1 '
              . $head1->title->present($self) . "\n\n"
              . 'Alt::Data::Frame::ButMore - Alternative implementation of Data::Frame with more features'
              . "\n\n";
        }
        else {
            return $self->SUPER::view_head1($head1);
        }
    }
}

my $raw_module_file = path( $distdir, 'lib', 'Data/Frame.pm' );
my $alt_module_file = path( $distdir, 'lib', 'Alt/Data/Frame/ButMore.pm' );

my $parser = Pod::POM->new();
my $pom    = $parser->parse_file( $raw_module_file . '' ) or die $parser->error;
my $pod_text = Pod::POM::View::Pod::SLOYD->print($pom);

my $text = $alt_module_file->slurp_utf8;
$text =~ s/^=head1.*/$pod_text/sm;
$alt_module_file->spew_utf8($text);

# output to README.md
my $pod_markdown = Pod::Markdown::Github->new();
$pod_markdown->output_string( \my $content );
$pod_markdown->parse_characters(1);
$pod_markdown->parse_string_document($pod_text);
path('README.md')->spew_utf8($content);

