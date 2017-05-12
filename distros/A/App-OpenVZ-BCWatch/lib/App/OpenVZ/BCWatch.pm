package App::OpenVZ::BCWatch;

use strict;
use warnings;
use boolean qw(true false);

use Carp qw(croak);
use File::Basename qw(basename);
use File::HomeDir ();
use File::Spec ();
use Mail::Sendmail qw(sendmail);
use Storable qw(store retrieve);
use Sys::Hostname qw(hostname);

our $VERSION = '0.04';

sub new
{
    my $class = shift;
    my %args = @_;

    my $defined_or = sub { defined $_[0] ? $_[0] : $_[1] };

    my $self = bless {
        Config => {
            input_file      => $args{input_file} || '/proc/user_beancounters',
            data_file       => $args{data_file}  || File::Spec->catfile(File::HomeDir->my_home, 'vzwatchd.dat'),
            _field_names    => [ qw(uid resource held maxheld barrier limit failcnt) ],
            _exclude_fields => [ qw(uid resource) ],
            monitor_fields  => $args{monitor_fields} || [ qw(failcnt) ],
            mail => {
                from    => $args{mail}->{from}    || 'root@localhost',
                to      => $args{mail}->{to}      || 'root@localhost',
                subject => $args{mail}->{subject} || 'vzwatchd: NOTICE',
            },
            sleep   => $defined_or->($args{sleep}, 60),
            verbose => $defined_or->($args{verbose}, false),
            _tests  => $defined_or->($args{_tests}, false),
        }
    }, ref($class) || $class;

    $self->_init;

    return $self;
}

sub process
{
    my $self = shift;

    delete @$self{qw(data stored)};

    $self->_get_data_running;
    $self->_get_data_file;
    $self->_compare_data;
    $self->_put_data_file;
}

sub _init
{
    my $self = shift;

    eval { store({}, $self->{Config}->{data_file}) }
      or croak "Cannot store to $self->{Config}->{data_file}: $!";

    my $pkg_tmpl = join '::', (__PACKAGE__, '_template');
    no strict 'refs';

    if (defined ${$pkg_tmpl}) {
        $self->{template} = ${$pkg_tmpl};
    }
    else {
        ${$pkg_tmpl} = $self->{template} = do {
            local $/ = '__END__';
            local $_ = <DATA>;
            chomp;
            s/^\s+//;
            s/\s+\z//;
            $_
        };
    }

    $self->{excluded} = {
        map {
          my $field = $_;
            (scalar grep $_ eq $field, @{$self->{Config}->{_exclude_fields}})
              ? ($field => true)
              : ($field => false)
        } @{$self->{Config}->{_field_names}}
    };

    my $i;
    $self->{index} = { map { $_ => $i++ } @{$self->{Config}->{_field_names}} };
}

sub _get_data_running
{
    my $self = shift;

    open(my $fh, '<', $self->{Config}->{input_file})
      or croak "Cannot read $self->{Config}->{input_file}: $!";
    my $output = do { local $/; <$fh> };
    close($fh);

    my $valid_format = join '\s+', @{$self->{Config}->{_field_names}};

    unless ($output =~ /$valid_format/) {
        croak "Format of $self->{Config}->{input_file} not recognized";
    }

    my $re = qr{
                      \s*?
         (?:\d+?\:)?  \s+?
         (?:\w+?)     \s+?
         (?:(?:\d+?)  \s*?){5}
    }x;

    my $uid;

    my @names = grep {
      !$self->{excluded}->{$_}
        ? $_ : ()
    } @{$self->{Config}->{_field_names}};

    local $1;
    while ($output =~ /^($re)$/gm) {
        my $line = $1;
        if ($line =~ /^ \s+? (\d+?)\:/gx) {
            $uid = $1;
        }
        my $res;
        if ($line =~ /\G \s+? (\w+)/gx) {
            $res = $1;
        }
        my @fields;
        if ($line =~ /\G \s+ (.*) $/x) {
            @fields = split /\s+/, $1;
        }
        push @{$self->{data}{$uid}{$res}},
          { map { $names[$_] => $fields[$_] } (0 .. $#fields) };
    }
}

sub _get_data_file
{
    my $self = shift;

    eval { $self->{stored} = retrieve($self->{Config}->{data_file}) }
      or croak "Cannot retrieve from $self->{Config}->{data_file}: $!";
}

sub _compare_data
{
    my $self = shift;

    my $has_changed = sub
    {
        my ($uid, $res, $i) = @_;

        my ($data, $stored) = map {
          my $type = $_; sub { $self->{$type}{$uid}{$res}->[$i]->{$_[0]} || 0 }
        } qw(data stored);

        return scalar grep { $data->($_) > $stored->($_) } @{$self->{Config}->{monitor_fields}};
    };

    foreach my $uid (sort {$a <=> $b} keys %{$self->{stored}}) {
        foreach my $res (sort {$a cmp $b} keys %{$self->{stored}{$uid}}) {
            foreach my $index (0 .. $#{$self->{stored}{$uid}{$res}}) {
                if ($has_changed->($uid, $res, $index)) {
                    $self->_create_report($uid, $res, $index);
                }
            }
        }
    }
}

sub _create_report
{
    my $self = shift;
    my ($uid, $res, $index) = @_;

    if ($self->{Config}->{_tests}) {
        push @{$self->{tests}->{report}}, $self->_prepare_report($uid, $res, $index);
    }
    else {
        my $report = $self->_prepare_report($uid, $res, $index);
        $self->_send_mail($report);

        if ($self->{Config}->{verbose}) {
            print "Report for \"$uid: $res\" sent to '$self->{Config}->{mail}->{to}'\n";
        }
    }
}

sub _put_data_file
{
    my $self = shift;

    eval { store($self->{data}, $self->{Config}->{data_file}) }
      or croak "Cannot store to $self->{Config}->{data_file}: $!";
}

sub _prepare_report
{
    my $self = shift;
    my ($uid, $res, $index) = @_;

    my @fixed_fields = ($uid, $res) x 2;
    my @mapping = (
        [
          { map {
            $_ => shift @fixed_fields,
          } @{$self->{Config}->{_exclude_fields}} },
          { map {
            $_ => $self->{stored}{$uid}{$res}->[$index]->{$_},
          } grep !$self->{excluded}->{$_}, @{$self->{Config}->{_field_names}} }
        ],
        [
          { map {
            $_ => shift @fixed_fields,
          } @{$self->{Config}->{_exclude_fields}} },
          { map {
            $_ => $self->{data}{$uid}{$res}->[$index]->{$_},
          } grep !$self->{excluded}->{$_}, @{$self->{Config}->{_field_names}} }
        ],
    );

    my @values;
    foreach my $map (@mapping) {
        my @v;
        foreach my $entry (@$map) {
            push @v, map $entry->{$_}, sort {
              $self->{index}->{$a} <=> $self->{index}->{$b}
            } keys %$entry;
        }
        push @values, [ @v ];
    }

    my %changed;
    foreach my $field (keys %{$mapping[0]->[1]}) {
        if ($mapping[0]->[1]->{$field} != $mapping[1]->[1]->{$field}) {
            $changed{$self->{index}->{$field}} = true;
        }
    }

    my $tmpl = \@values;
    my $report = $self->{template};

    local $1;

    while (my ($var) = $report =~ /(\$\S+)/) {
        unless ($report =~ /\Q$var\E$/m) {
            my $len = length($var) - length do { eval $var };
            $report =~ s/(?<=\Q$var\E)/' ' x $len/e;
        }
        $report =~ s/(\Q$var\E)/$1/ee;
    }

    while (my ($pos) = $report =~ /\((\d+)\)/) {
        my $marked = $changed{$pos} ? '*' : ' ';
        $report =~ s/\($pos\)/  $marked/;
    }

    return $report;
}

sub _send_mail
{
    my $self = shift;
    my ($report) = @_;

    my %mail = (
        From    => $self->{Config}->{mail}->{from},
        To      => $self->{Config}->{mail}->{to},
        Subject => $self->{Config}->{mail}->{subject},
        Message => <<EOT,
${\hostname}

$report

-- 
${\basename($0)} v$VERSION - ${\scalar localtime}
EOT
);
    sendmail(%mail)
      or croak "Cannot send mail: $Mail::Sendmail::error";
}

1;
__DATA__

Old:                          New:
----                          ----
Uid: $tmpl->[0][0]        (0) Uid: $tmpl->[1][0]
Res: $tmpl->[0][1]        (1) Res: $tmpl->[1][1]
Held: $tmpl->[0][2]       (2) Held: $tmpl->[1][2]
Maxheld: $tmpl->[0][3]    (3) Maxheld: $tmpl->[1][3]
Barrier: $tmpl->[0][4]    (4) Barrier: $tmpl->[1][4]
Limit: $tmpl->[0][5]      (5) Limit: $tmpl->[1][5]
Failcnt: $tmpl->[0][6]    (6) Failcnt: $tmpl->[1][6]

__END__

=head1 NAME

App::OpenVZ::BCWatch - Monitor the OpenVZ user_beancounters file

=head1 SYNOPSIS

 use App::OpenVZ::BCWatch;

 $watch = App::OpenVZ::BCWatch->new;
 $watch->process;

=head1 DESCRIPTION

C<App::OpenVZ::BCWatch> monitors the F</proc/user_beancounters> file and sends
mail notifications whenever important values change (as defined by the user).

The recommended usage of this application module is to use the provided
L<vzwatchd> daemon.

Version 2.5 of the F<user_beancounters> file is supported.

=head1 CONSTRUCTOR

=head2 new

 $watch = App::OpenVZ::BCWatch->new;

Instantiate an C<App::OpenVZ::BCWatch> object.

=head1 METHODS

=head2 process

 $watch->process;

Inspect whether the F<user_beancounters> file differs from the last run,
and if, report the differences via mail.

=head1 DAEMON USAGE

Run L<vzwatchd> as root without arguments to obtain a list of commands.

=head1 CONFIGURATION FILE

When L<vzwatchd> is I<started> initially, the F</etc/vzwatchd.conf> file
will be generated. The configuration will then subsequently remain inactive
until the C<_active> flag is either set within or deleted from the
configuration file.

=head2 Syntax

The configuration file is being parsed by L<Config::File>. Unless noted
otherwise, each option takes exactly one value. Specifying more than one
value for an option requires that the values are separated by whitespace.

=head2 Options

Adjustable options with defaults are:

=over 4

=item * C<mail[from]>

Mail sender address. Defaults to C<root@localhost>.

=item * C<mail[to]>

Mail recipient address. Defaults to C<root@localhost>.

=item * C<mail[subject]>

Mail subject line. Defaults to: C<vzwatchd: NOTICE>.

=item * C<monitor_fields>

One or more field names to monitor for changes. Defaults to: C<failcnt>.

=item * C<sleep>

Sleep interval in seconds. Defaults to 60.

=item * C<verbose>

Be verbose? Defaults to false.

=item * C<_active>

Configuration active? Defaults to false.

=back

Additional options with defaults are:

=over 4

=item * C<input_file>

Location of the F<user_beancounters> file. Defaults to F</proc/user_beancounters>.

=item * C<data_file>

Location of the data file. Defaults to F<$HOME/vzwatchd.dat>.

=back

=head1 CURRENT LIMITATIONS

=over 4

=item * Cannot parse anything else than the F<user_beancounters> file.

=item * Only version 2.5 of the F<user_beancounters> file is known to work.

=item * Fixed mail report template.

=item * No more than one mail recipient.

=back

=head1 BUGS & CAVEATS

Note that the sender and recipient mail address options with defaults
might require adjustment in order for notifications to be delivered.

=head1 SEE ALSO

L<OpenVZ::BC>, L<http://openvz.org>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
