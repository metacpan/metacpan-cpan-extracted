use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    section => {
        description => 'a section with a few members',
        error_msg   => 'cannot find "section" in config',
        members => {
            foo => {
                # value restriction either with a regex..
                value => qr{f.*},
                description => 'a string beginning with "f"'
            },
            bar => {
                # ..or with a validator callback.
                validator => sub {
                    my $self   = shift;
                    my $parent = shift;
                    # undef is "no-error" -> success.
                    no strict 'refs';
                    return undef
                        if $self->{value} == 42;
                }
            },
            wuu => {
                optional => 1
            }
        }
    }
};

my $p = Data::Processor->new($schema);

my $data = {
    section => {
        foo => 'frobnicate',
        bar => 42,
        # "wuu" being optional, can be omitted..
    }
};

my $error_collection = $p->validate($data, verbose=>0);
# no errors :-)

ok ($error_collection->count==0, 'no errors');



done_testing;
