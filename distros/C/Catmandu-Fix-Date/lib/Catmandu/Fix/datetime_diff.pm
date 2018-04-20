package Catmandu::Fix::datetime_diff;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:is :check :array);
use DateTime::Format::Strptime;
use DateTime::TimeZone;
use DateTime::Locale;
use DateTime;
use Catmandu::Fix::Has;

our $VERSION = "0.0132";

with 'Catmandu::Fix::Base';

has path => (
    fix_arg => 1
);
has start => (
    fix_arg => 1
);
has end => (
    fix_arg => 1
);
has start_time_zone => (
    fix_opt => 1,
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "UTC"
    }
);
has end_time_zone => (
    fix_opt => 1,
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "UTC"
    }
);

has validate => (
    fix_opt => 1,
    is => 'ro',
    required => 0,
    lazy => 1,
    default => sub { 1; }
);

has delete => (
    fix_opt => 1,
    is => 'ro'
);
has start_pattern => (
    fix_opt => 1,
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "%FT%T.%NZ"
    }
);
has end_pattern => (
    fix_opt => 1,
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "%FT%T.%NZ"
    }
);
has start_locale => (
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "en_US"
    }
);
has _start_locale => (
    is => 'ro',
    required => 0,
    lazy => 1,
    builder => '_build_start_locale'
);
has end_locale => (
    is => 'ro',
    required => 1,
    isa => sub {
        check_string($_[0]);
    },
    default => sub {
        "en_US"
    }
);
has _end_locale => (
    is => 'ro',
    required => 0,
    lazy => 1,
    builder => '_build_end_locale'
);

has _start_time_zone => (
    is => 'ro',
    required => 0,
    lazy => 1,
    builder => '_build_start_time_zone'
);
has _end_time_zone => (
    is => 'ro',
    required => 0,
    lazy => 1,
    builder => '_build_end_time_zone'
);

has _start_datetime_parser => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = $_[0];
        DateTime::Format::Strptime->new(
            pattern => $self->start_pattern,
            locale => $self->_start_locale,
            time_zone => $self->_start_time_zone,
            on_error => 'undef'
        );
    }
);
has _end_datetime_parser => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = $_[0];
        DateTime::Format::Strptime->new(
            pattern => $self->end_pattern,
            locale => $self->_end_locale,
            time_zone => $self->_end_time_zone,
            on_error => 'undef'
        );
    }
);

sub _get_locale {
    state $l = {};
    my $name = $_[0];
    $l->{$name} ||= DateTime::Locale->load($name);
}
sub _get_time_zone {
    state $t = {};
    my $name = $_[0];
    $t->{$name} = DateTime::TimeZone->new( name => $name );
}
sub _build_start_locale {
    _get_locale($_[0]->start_locale);
}
sub _build_end_locale {
    _get_locale($_[0]->end_locale);
}
sub _build_start_time_zone {
    _get_time_zone( $_[0]->start_time_zone );
}
sub _build_end_time_zone {
    _get_time_zone( $_[0]->end_time_zone );
}

sub emit {
    my($self,$fixer) = @_;

    my @perl;

    my $path = $fixer->split_path($self->path());
    my $start = $fixer->split_path($self->start());
    my $start_key = pop @$start;
    my $end = $fixer->split_path($self->end());
    my $end_key = pop @$end;

    my $start_time_zone = $fixer->capture($self->_start_time_zone());
    my $start_locale = $fixer->capture($self->_start_locale());
    my $end_time_zone = $fixer->capture($self->_end_time_zone());
    my $end_locale = $fixer->capture($self->_end_locale());

    my $start_parser = $fixer->capture($self->_start_datetime_parser());
    my $end_parser = $fixer->capture($self->_end_datetime_parser());

    #cf. http://www.nntp.perl.org/group/perl.datetime/2012/05/msg7838.html
    push @perl, "local \$Params::Validate::NO_VALIDATION = ".($self->validate() ? 0 : 1).";";

    push @perl, $fixer->emit_walk_path( $fixer->var, $start, sub {

        my $p_start_var = shift;

        $fixer->emit_get_key( $p_start_var, $start_key, sub {

            my $start_var = shift;

            $fixer->emit_walk_path( $fixer->var, $end, sub {

                my $p_end_var = shift;

                $fixer->emit_get_key( $p_end_var, $end_key, sub {

                    my $end_var = shift;

                    my $dt_start = $fixer->generate_var();
                    my $dt_end = $fixer->generate_var();

                    my @p;

                    push @p, $fixer->emit_declare_vars($dt_start);
                    push @p, $fixer->emit_declare_vars($dt_end);

                    #start: no parsing needed (fast)
                    if($self->start_pattern() =~ /\s*%s\s*/o){
                        push @p, "if( is_string(${start_var}) ) {";
                        push @p, "     ${start_var} =~ s\/^\\s+|\\s+\$\/\/go;";
                        push @p, "     $dt_start = DateTime->from_epoch(epoch => ${start_var},time_zone => ${start_time_zone},locale => ${start_locale});";
                        push @p, "}"
                    }
                    #start: parsing needed (slow)
                    else{
                        push @p, " $dt_start = ".${start_parser}."->parse_datetime(${start_var}) if is_string(${start_var});";
                    }
                    #end: no parsing needed (fast)
                    if($self->end_pattern() =~ /\s*%s\s*/o){
                        push @p, "if( is_string(${end_var}) ) {";
                        push @p, "     ${end_var} =~ s\/^\\s+|\\s+\$\/\/go;";
                        push @p, "     $dt_end = DateTime->from_epoch(epoch => ${end_var},time_zone => ${end_time_zone},locale => ${end_locale});";
                        push @p, "}"
                    }
                    #end: parsing needed (slow)
                    else{
                        push @p, " $dt_end = ".${end_parser}."->parse_datetime(${end_var}) if is_string(${end_var});";
                    }

                    push @p, " if($dt_start && $dt_end){";

                    push @p, $fixer->emit_create_path( $fixer->var, $path, sub {

                        my $var = shift;
                        "   ${var} = $dt_end->subtract_datetime_absolute( $dt_start )->seconds();";

                    });

                    push @p, " }";

                    if($self->delete){
                        my $dest_path = [@$path];
                        my $dest_key = pop @$dest_path;
                        push @p, " else { ";
                        push @p, $fixer->emit_walk_path( $fixer->var, $dest_path, sub {
                            my $p_dest = shift;
                            $fixer->emit_delete_key( $p_dest, $dest_key );
                        });
                        push @p, " }";
                    }

                    join('', @p);


                });

            });

        });

    });


    join('',@perl);
}

1;
__END__

=head1 NAME

Catmandu::Fix::datetime_diff - Catmandu Fix to compute difference in seconds between two datetimes

=head1 SYNOPSIS

  datetime_diff('diff','startTime','endTime',
    'start_pattern' => '%Y-%m-%d',
    'end_pattern' => '%Y-%m-%d',
    'start_time_zone' => 'UTC',
    'end_time_zone' => 'Europe/Brussels',
    'delete' => 1,
    validate => 0,
    start_locale => 'en_US',
    end_locale => 'nl_NL'
  )

=head1 OPTIONS

=over 4

=item start_pattern

Pattern of the start date string to parse. See L<DateTime::Format::Strptime>
for documentation of the format. The default is C<%FT%T.%NZ> (UTC datetime string).

=item end_pattern

Pattern of the end date string. See L<DateTime::Format::Strptime>
for documentation of the format. The default is C<%FT%T.%NZ> (UTC datetime string).

=item start_time_zone

Time zone of the start date string. In case the start date string does not
contain any time zone information, the parser will use this time_zone to
interpret the date. When not set correctly, the resulting date string will be
wrong. The default value is C<UTC>. For a complete list of time zone codes see
L<http://en.wikipedia.org/wiki/List_of_tz_database_time_zones>.

Most parsers assume 'local', but this can lead to different results on
different systems. 'local' simply means the same time zone as the one
configured on your system.

=item end_time_zone

Time zone of the end date string. In case the end date string does not
contain any time zone information, the parser will use this time_zone to
interpret the date. When not set correctly, the resulting date string will be
wrong. The default value is C<UTC>. For a complete list of time zone codes see
L<http://en.wikipedia.org/wiki/List_of_tz_database_time_zones>.

Most parsers assume 'local', but this can lead to different results on
different systems. 'local' simply means the same time zone as the one
configured on your system.

=item start_locale

Language code for the start date string. This is only important when your date
string contains names of week days or months. For a complete list of locale
codes see L<DateTime::Locale::Catalog>. The default value is C<en_US>.

=item end_locale

Language code for the end date string. This is only important when your date
string contains names of week days or months. For a complete list of locale
codes see L<DateTime::Locale::Catalog>. The default value is C<en_US>.

=item delete

Delete the key when either start or end date string cannot be parsed. When used, the
option C<default> is ignored. Disabled (C<0>) by default.

=item validate

Validate start and end date string when parsing. Disabled (C<0>) by default to
increase speed.

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
