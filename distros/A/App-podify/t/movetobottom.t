use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec;

my $podify = do 'script/podify.pl' or die $@;

$podify->{perl_module} = File::Spec->catfile(dirname(__FILE__), 'InlineModule.pm');
$podify->init;

$podify->parse;
ok $podify->{documented}{too_cool}, 'pod too_cool';
ok !$podify->{documented}{not_documented}, 'pod not_documented';
ok $podify->{subs}{too_cool},       'sub too_cool';
ok $podify->{subs}{not_documented}, 'sub not_documented';

$podify->post_process;
ok !$podify->{subs}{too_cool}, 'sub too_cool removed';

open my $OUT, '>', \my $out;
$podify->generate($OUT);
my @out = map {"$_\n"} split /\n/, $out;

while (<DATA>) {
  my $desc = $_;
  $desc =~ s![^-=\w.]! !g;
  is shift(@out), $_, "line $. ($desc)" or last;
}

done_testing;

__DATA__
package Some::Module;
use strict;
use warnings;

our $VERSION = '0.2';

has cool => 123;

sub too_cool {
}

sub not_documented {
}

1;

=encoding utf8

=head1 NAME

Some::Module - Should be moved to bottom

=head1 ATTRIBUTES

=head2 cool

Aweful documentation.

=head1 METHODS

=head2 too_cool

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

__DATA__
This should be the last line
