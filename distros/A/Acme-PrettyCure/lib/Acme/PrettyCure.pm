package Acme::PrettyCure;
use Any::Moose;
use 5.10.0;
our $VERSION = '0.02';

use feature 'switch';
use UNIVERSAL::require;

sub members {
    my ($class, $team) = @_;
    $team ||= 'First';

    given ($team) {
        when ('AllStar') {
            return $class->_get(
                qw(CureBlack CureWhite ShinyLuminous 
                   CureBloom CureEgret 
                   CureDream CureRouge CureLemonade CureMint CureAqua MilkyRose 
                   CurePeach CureBerry CurePine CurePassion 
                   CureBlossom CureMarine CureSunshine CureMoonlight)
            );
        }
        when ('AllStarDX1') {
            return $class->_get(
                qw(CureBlack CureWhite ShinyLuminous 
                   CureBloom CureEgret 
                   CureDream CureRouge CureLemonade CureMint CureAqua MilkyRose 
                   CurePeach CureBerry CurePine)
            );
        }
        when ('AllStarDX2') {
            return $class->_get(
                qw(CureBlack CureWhite ShinyLuminous 
                   CureBloom CureEgret 
                   CureDream CureRouge CureLemonade CureMint CureAqua MilkyRose 
                   CurePeach CureBerry CurePine CurePassion 
                   CureBlossom CureMarine)
            );
        }
        when ('First') {
            return $class->_get(qw(CureBlack CureWhite));
        }
        when ('MaxHeart') {
            return $class->_get(qw(CureBlack CureWhite ShinyLuminous));
        }
        when ('SplashStar') {
            return $class->_get(qw(CureBloom CureEgret));
        }
        when ('Five') {
            return $class->_get(
                qw(CureDream CureRouge CureLemonade CureMint CureAqua));
        }
        when ('FiveGoGo') {
            return $class->_get(
                qw(CureDream CureRouge CureLemonade CureMint CureAqua MilkyRose)
            );
        }
        when ('Fresh') {
            return $class->_get(qw(CurePeach CureBerry CurePine CurePassion));
        }
        when ('HeartCatch') {
            return $class->_get(qw(CureBlossom CureMarine CureSunshine CureMoonlight));
        }
        default {
            die "can't find $team at pretty cure";
        }
    }
}

sub now { shift->members('HeartCatch') }

sub _get {
    my ($class, @names) = @_;

    my @girls;
    for my $name (@names) {
        my $module = "Acme::PrettyCure::$name";
        $module->require or die $@;

        push @girls, $module->new;
    }

    return @girls;
}


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Acme::PrettyCure - All about Japanese battle heroine "Pretty Cure"

=head1 SYNOPSIS

  use Acme::PrettyCure;

  # retrieve member on their teams
  my @allstar =  Acme::PrettyCure->members('AllStar');    # retrieve all
  my @allstar1 = Acme::PrettyCure->members('AllStarDX1'); # retrieve first .. fresh
  my @allstar2 = Acme::PrettyCure->members('AllStarDX2'); # retrieve first .. heart_catch
  my @first    = Acme::PrettyCure->members;
  my @mh       = Acme::PrettyCure->members('MaxHeart');
  my @ss       = Acme::PrettyCure->members('SplashStar');
  my @five     = Acme::PrettyCure->members('Five');

  my $hc = Acme::PrettyCure->now; # retrieve active team members

=head1 DESCRIPTION

"Acme::PrettyCure" is most famous Japanese battle hiroine.

http://en.wikipedia.org/wiki/Pretty_Cure

=head1 METHODS

=head2 members

  my @precures = Acme::PrettyCure->members('AllStar');

returns Acme::PrettyCure::Girl based objects.

=head1 AUTHOR

Kan Fushihara E<lt>kan.fushihara at gmail.comE<gt>

=head1 SEE ALSO

C<Acme::MorningMusume>, C<Acme::AKB48>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
