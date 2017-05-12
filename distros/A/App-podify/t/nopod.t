use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec;

my $podify = do 'script/podify.pl' or die $@;

$ENV{PODIFY_AUTHOR} = 'superman';

$podify->{perl_module} = File::Spec->catfile(dirname(__FILE__), 'NoPOD.pm');
$podify->init;
$podify->parse;
$podify->post_process;

open my $OUT, '>', \my $out;
$podify->generate($OUT);
$out =~ s!=head1 AUTHOR.*?=!=head1 AUTHOR\n\nPLACEHOLDER\n\n=!s;
my @out = map {"$_\n"} split /\n/, $out;

while (<DATA>) {
  my $desc = $_;
  $desc =~ s![^-=\w.]! !g;
  is shift(@out), $_, "line $. ($desc)" or last;
}

done_testing;

__DATA__
package Unknown::Module;
use Mojo::Base -base;

our $VERSION = '0.01';

has replace_me => sub { };

sub replace_me {
  my $self = shift;
}

1;

=encoding utf8

=head1 NAME

Unknown::Module - TODO

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 ATTRIBUTES

=head2 replace_me

=head1 METHODS

=head2 replace_me

=head1 AUTHOR

PLACEHOLDER

=head1 COPYRIGHT AND LICENSE

TODO

=head1 SEE ALSO

TODO

=cut
