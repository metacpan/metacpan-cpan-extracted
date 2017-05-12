package Data::Pipeline::Adapter::FetchPage;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Types qw( Iterator );

use LWP;

has url => (
    isa => Iterator,
    is => 'rw',
    required => 1,
    coerce => 1
);

has cut_start => (
    isa => 'Str',
    is => 'rw',
    required => 1
);

has cut_end => (
    isa => 'Str',
    is => 'rw',
    required => 1
);

has split => (
    isa => 'Str',
    is => 'rw',
    required => 1
);

has '+source' => (
    default => sub {
        my $self = shift;
        my $start = -1;
        my $inc = length($self -> split);
        my $end;
        my $content;

        Data::Pipeline::Iterator::Source -> new(
            has_next => sub { $start != -1 || !$self -> url -> finished },
            get_next => sub { 
                if( $start == -1 ) {
                    return +{ content => '' } if $self -> url -> finished;
                    $content = $self -> fetch_page;
                    $start = 0;
                    $end = index( $content, $self -> split );
                }
                my $c;
                if( $end == -1 ) {
                     $c = substr($content, $start);
                     $start = -1;
                }
                else {
                    $c = substr($content, $start, $end - $start ); 
                    $start = $end + $inc;
                    $end = index( $content, $self -> split, $start );
                }
                #print STDERR "content: [$c]\n";
                return +{ content => $c };
            }
        );
    }
);

sub fetch_page {
    my($self) = @_;

    return '' if $self -> url -> finished;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $u;
    my $response = $ua->get($u = $self -> url -> next);

    unless ($response->is_success) {
        Carp::croak $response->status_line;
    }

    my $content = $response -> content;
    
    my $start = index($content, $self -> cut_start);
    my $end = rindex( $content, $self -> cut_end );

    return substr($content, $start, $end - $start);
}

1;

__END__

=head1 NAME

Data::Pipeline::Adapter::FetchPage - fetch a web page and split it into items

=head1 SYNOPSIS

 use Data::Pipeline qw( FetchPage );

 Pipeline(
     FetchPage(
         cut_begin => ...,
         cut_end => ...,
         split => ...,
         url => ...
     )
 )

=head1 DESCRIPTION




