#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.020;
use strict;
use warnings;

package App::Magpie::Action::Old::Module;
# ABSTRACT: module that has a newer version available
$App::Magpie::Action::Old::Module::VERSION = '2.010';
use List::AllUtils qw{ each_array };
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use App::Magpie::Constants qw{ $SHAREDIR };
use App::Magpie::URPM;


# -- private vars

my (@SKIP_MOD_NAME, @SKIP_MOD_VERSION);
{
    my $skipfile = $SHAREDIR->child( 'modules.skip' );
    my @skips = $skipfile->lines;
    foreach my $skip ( @skips ) {
        next if $skip =~ /^#/;
        chomp $skip;
        my ($module, $version, $reason) = split /\s*;\s*/, $skip;
        $version ||= ".*"; # no version: all versions are skipped
        push @SKIP_MOD_NAME,    qr/^$module$/;
        push @SKIP_MOD_VERSION, qr/^$version$/;
    }
}

my %SKIPPKG = do {
    my $skipfile = $SHAREDIR->child( 'packages.skip' );
    my @skips = $skipfile->lines;
    my %skip;
    foreach my $skip ( @skips ) {
        next if $skip =~ /^#/;
        chomp $skip;
        my ($pkg, $reason) = split /\s*;\s*/, $skip;
        $skip{$pkg} = 1;
    }
    %skip;
};


# -- public attributes


has name     => ( ro, isa => "Str", required );
has oldver   => ( ro, isa => "Str" );
has newver   => ( ro, isa => "Str" );
has is_core  => ( rw, isa => "Bool" );
has packages => ( ro, isa => "ArrayRef", lazy_build, auto_deref );

sub _build_packages {
    my ($self) = @_;
    my $urpm = App::Magpie::URPM->instance;
    my $module = $self->name;
    my %seen;   # to remove packages in both i586 & x86_64 medias
    my @pkgs   =
        grep { ! $seen{ $_->name }++ }
        $urpm->packages_providing( $module );

    my $iscore = scalar( grep { $_->name =~ /^perl(-base)?$/ } @pkgs );
    $self->set_is_core( !!$iscore );
    return [ grep { $_->name !~ /^perl(-base)?$/ } @pkgs ];
}


# -- public methods


sub category {
    my ($self) = @_;
    my @pkgs   = $self->packages;
    my $iscore = $self->is_core;

    return "ignored" if $self->is_ignored;

    if ( $iscore ) {
        return "core"       if scalar(@pkgs) == 0;
        return "strange"    if scalar(@pkgs) >= 2;
        # scalar(@pkgs) == 1;
        return "ignored" if exists $SKIPPKG{ $pkgs[0] };
        return "dual-lifed";
    }

    return "orphan"  if scalar(@pkgs) == 0;
    return "strange" if scalar(@pkgs) >= 2;
    # scalar(@pkgs) == 1;
    return "ignored"    if exists $SKIPPKG{ $pkgs[0]->name };
    return "null_old"   if $self->oldver eq "0" || $self->oldver eq "undef";
    return "null_new"   if $self->newver eq "0" || $self->newver eq "undef";
    return "nodiff"     if $self->oldver eq $self->newver; # cpan can be confused
    return "unparsable" if $self->oldver eq "Unparsable";
    return "normal";
}



sub is_ignored {
    my $self = shift;

    # check if module is ignored, regex comparison
    my $it =  each_array @SKIP_MOD_NAME, @SKIP_MOD_VERSION;
    while ( my ($mod, $ver) = $it->() ) {
        return 1 if $self->name =~ $mod && $self->newver =~ $ver;
    }

    return 0;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Old::Module - module that has a newer version available

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This class represents an installed Perl module that has a newer version
available on CPAN.

=head1 ATTRIBUTES

=head2 name

The name of the module.

=head2 oldver

The version of the module as currently installed.

=head2 newver

The module version, as available on CPAN.

=head2 packages

The Mageia packages holding the module (there can be more than one).
Core packages (perl and perl-base) are excluded from this list.

=head2 is_core

Whether the module is shipped in a core Perl package.

=head1 METHODS

=head2 category

    my $str = $module->category;

Return the module category:

=over 4

=item * C<core> - one of the core packages (perl, perl-base)

=item * C<dual-lifed> - core package + one other package

=item * C<normal> - plain, non-core regular package

=item * C<orphan> - installed package not shipped by a package
(inherited from mandriva, or not yet submitted)

=item * C<strange> - shipped by more than one non-core package

=item * C<nodiff> - when cpan reports a difference although there isn't

=item * C<null> - when old or new versions are 0.0000

=item * C<unparsable> - current version unparsable

=back

=head2 is_ignored

    my $bool = $module->is_ignored;

Return true if C<$module> is ignored due to its presence in
F<SHAREDIR/modules.skip>. Note that it will not match against
F<SHAREDIR/packages.skip>.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
