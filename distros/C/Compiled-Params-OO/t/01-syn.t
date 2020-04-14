use Test::More; 
{
	package Life;
	use Compiled::Params::OO qw/cpo/;
       	use Types::Standard qw/Str Int/;
	our $validate;
        BEGIN {
                $validate = cpo(
                        time => {
                                testing => Int,
                                me => {
                                        type => Str,
                                        default => sub {
                                                return 'insanity';
                                        }
                                }
                        },
                        circles => [Str, Int]
                );
        }

        sub new {
                return bless {}, $_[0];
        }

        sub time {
                my $self = shift;
                my $params = $validate->time->(
                        testing => 16000000,
                );
                return $params->me;
        }

        sub circles {
                my $self = shift;
                my @params = $validate->circles->('dreaming', 211000000);
                return \@params;
        }
}

my $t = Life->new->time;
is($t, 'insanity');

done_testing;
