package App::FileSummoner::Register;
BEGIN {
  $App::FileSummoner::Register::VERSION = '0.005';
}

use 5.006;
use strict;
use warnings;

=head1 NAME

App::FileSummoner::Register - Skeletons register

=cut

my ( @rules, %skeleton );

=head1 SYNOPSIS

    registerSkeleton(qr/\.pm$/, 'perl/skeleton.pm');

    my $skeleton = chooseSkeleton('some/path/Module.pm');

=head1 EXPORT

=over 2

=item registerSkeleton

=item chooseSkeleton

=back

=cut

use Exporter 'import';
our @EXPORT_OK = qw(registerSkeleton chooseSkeleton);

=head1 SUBROUTINES

=head2 registerSkeleton

Register new skeleton for a given rule. Use in I<rules.pl> file.

=cut

sub registerSkeleton {
    my ( $rule, $skeleton ) = @_;

    return if defined $skeleton{$rule};
    push @rules, $rule;
    $skeleton{$rule} = $skeleton;
}

=head2 chooseSkeleton

Choose the best skeleton for a given file.

=cut

sub chooseSkeleton {
    my ($fileName) = @_;

    foreach my $rule (@rules) {
        return $skeleton{$rule} if ruleMatches( $rule, $fileName );
    }

    return undef;
}

=head2 unregisterAll

=cut

sub unregisterAll {
    @rules = ();
    %skeleton = ();
}

=head2 ruleMatches

Check if a filename matches a given rule.

=cut

sub ruleMatches {
    my ( $rule, $fileName ) = @_;

    return rulesMatches( $rule, $fileName ) if ref $rule eq 'ARRAY';
    return &$rule($fileName) if ref $rule eq 'CODE';
    return $fileName =~ $rule;
}

sub rulesMatches {
    my ( $rulesRef, $fileName ) = @_;

    foreach my $rule (@{ $rulesRef }) {
        ruleMatches($rule, $fileName) || return 0;
    }
    return 1;
}

1;
