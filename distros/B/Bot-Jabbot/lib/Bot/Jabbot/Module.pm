package Bot::Jabbot::Module;
use warnings;
use strict;
use Data::Localize;

=item new()

    standart C<new> method

=cut

sub new {
    my $class = shift;
    my $lang = shift;

#    my $name = ref($class) || $class;
#    $name =~ s/^.*:://;

    my $self = {};
#    $self->{Name} ||= $name;


    my $calldir = $class;
    $calldir =~ s{::}{/}g;
    my $file = "$calldir.pm";
    my $path = $INC{$file};
    $path =~ s{\.pm$}{/I18N};

    $self->{loc} = Data::Localize->new();
    $self->{loc}->add_localizer( 
        class => "Gettext",
        path  => $path."/*.po"
    );
    $self->{loc}->auto(1);
    $self->{loc}->set_languages($lang);

    bless $self, $class;


    return $self;
}

=item init()

    called on module load, used for timers binding, etc.

=cut

sub init { undef }

=item setlang()

    sets current language

=cut

sub setlang
{
    my ($self,$lang) =@_;
    $self->{loc}->set_languages($lang);
}

=item loc()

    shorthand for Data::Localize->localize method

=cut

sub loc
{
    my $self=shift;
    $self->{loc}->localize(@_);
}

1;