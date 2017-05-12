package MyTestApp::Lexicon;

use Dancer ':syntax';

sub new {
    my $class = shift;
    my $self = {
                dictionary => {
                               en => {
                                      try => "I am english now",
                                     },
                               it => {
                                      try => "Sono in italiano",
                                     },
                              }
               };
    bless $self, $class;
}

sub dictionary {
    return shift->{dictionary};
}

sub localize {
    my ($self, $string) = @_;
    my $lang = session('lang') || var('lang');
    return $string unless $lang;
    return $string unless $self->dictionary->{$lang};
    my $tr = $self->dictionary->{$lang}->{$string};
    defined $tr ? return $tr : return $string;
}


1;
