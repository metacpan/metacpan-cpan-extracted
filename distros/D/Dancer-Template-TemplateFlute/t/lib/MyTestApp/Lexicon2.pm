package MyTestApp::Lexicon2;

use Dancer ':syntax';

sub new {
    my ($class, %params) = @_;
    my $self = {
                dictionary => {
                               en => {
                                      try => "I am english now",
                                     },
                               it => {
                                      try => "Sono in italiano",
                                     },
                              },
                %params,
               };
    bless $self, $class;
}

sub dictionary {
    return shift->{dictionary};
}

sub prepend {
    return shift->{prepend};
}

sub append {
    return shift->{append};
}


sub try_to_translate {
    my ($self, $string) = @_;
    my $lang = session('lang') || var('lang');
    return $string unless $lang;
    return $string unless $self->dictionary->{$lang};
    my $tr = $self->dictionary->{$lang}->{$string};
    defined $tr ? return $self->prepend . $tr . $self->append : return $string;
}


1;
