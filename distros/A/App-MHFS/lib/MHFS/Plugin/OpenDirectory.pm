package MHFS::Plugin::OpenDirectory v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';

sub new {
    my ($class, $settings) = @_;
    my $self =  {};
    bless $self, $class;

    my $odmappings = $settings->{OPENDIRECTORY}{maps};

    $self->{'routes'} = [
        [
            '/od', sub {
                my ($request) = @_;
                $request->SendRedirect(301, 'od/');
            }
        ],
        [
            '/od/*', sub {
                my ($request) = @_;
                foreach my $key (keys %{$odmappings}) {
                    if(rindex($request->{'path'}{'unsafepath'}, '/od/'.$key, 0) == 0) {
                        $request->SendDirectoryListing($odmappings->{$key}, '/od/'.$key);
                        return;
                    }
                }
                $request->Send404;
            }
        ],
    ];

    return $self;
}

1;
