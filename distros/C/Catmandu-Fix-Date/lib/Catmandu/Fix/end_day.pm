package Catmandu::Fix::end_day;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:is :check :array);
use DateTime::Format::Strptime;
use DateTime::TimeZone;
use DateTime;

our $VERSION = "0.0132";

with 'Catmandu::Fix::Base';

has path => (
    is => 'ro' ,
    required => 1
);
has add => (
    is => 'ro',
    isa => sub { check_integer($_[0]); },
    required => 0,
    lazy => 1,
    default => sub { 0; }
);
has time_zone => (
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "UTC"
    }
);
has pattern => (
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "%FT%T.%NZ"
    }
);

around BUILDARGS => sub {
    my($orig,$class,$path,%args) = @_;

    $orig->($class,
        path => $path,
        %args
    );

};

sub emit {
    my($self,$fixer) = @_;

    my $path = $fixer->split_path($self->path());
    my $end_day = $fixer->capture(sub{
        my $skip = shift;
        my $d = DateTime->now->set_time_zone($self->time_zone)->truncate(to => "day");
        if(is_integer($skip)){
            $d->add(days => $skip);
        }
        $d->add(days => 1,seconds => -1);
        $d;
    });

    $fixer->emit_create_path($fixer->var,$path,sub{

        my $var = shift;

        my $d = $fixer->generate_var();
        my $p  = $fixer->emit_declare_vars($d);
        $p .= " $d = ${end_day}->(".$self->add().");";
        $p .= " ${var} = DateTime::Format::Strptime::strftime('".$self->pattern()."',$d);";

        $p;

    });

}

1;
__END__

=head1 NAME

Catmandu::Fix::end_day - Catmandu Fix retrieving date string for end of the current day

=head1 SYNOPSIS

  #get end of the day in the time zone Europe/Brussels
  end_day('end_day','pattern' => '%Y-%m-%dT%H:%M:SZ','time_zone' => 'Europe/Brussels')

  #get end of the day tomorrow in the time zone Europe/Brussels
  end_day('end_day','pattern' => '%Y-%m-%dT%H:%M:SZ','time_zone' => 'Europe/Brussels', 'add' => 1)

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
