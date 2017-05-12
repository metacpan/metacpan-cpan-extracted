package App::CPANTS::Lint;

use strict;
use warnings;
use Carp;
use Module::CPANTS::Analyse;

our $VERSION = '0.05';

sub new {
    my ($class, %opts) = @_;
    $opts{no_capture} = 1 if !defined $opts{no_capture};
    $opts{dump} = 1 if $opts{yaml} || $opts{json};
    if ($opts{metrics_path}) {
        Module::CPANTS::Analyse->import(@{$opts{metrics_path}});
    }
    bless {opts => \%opts}, $class;
}

sub lint {
    my ($self, $dist) = @_;

    croak "Cannot find $dist" unless -f $dist;

    my $mca = $self->{mca} = Module::CPANTS::Analyse->new({
        dist => $dist,
        opts => $self->{opts},
    });
    my $res = $self->{res} = {dist => $dist};

    {
        if (-f $dist and my $error = $mca->unpack) {
            warn "$dist: $error\n" and last;
        }
        $mca->analyse;
    }
    $mca->calc_kwalitee;

    my $kwl = $mca->d->{kwalitee};
    my %err = %{ $mca->d->{error} || {} };
    my (%fails, %passes);
    for my $ind (@{$mca->mck->get_indicators}) {
        if ($ind->{needs_db}) {
            push @{$res->{ignored} ||= []}, $ind->{name};
            next;
        }
        if ($mca->can('x_opts') && $mca->x_opts->{ignore}{$ind->{name}} && $ind->{ignorable}) {
            push @{$res->{ignored} ||= []}, $ind->{name};
            next;
        }
        next if ($kwl->{$ind->{name}} || 0) > 0;
        my $type = $ind->{is_extra} ? 'extra' :
                   $ind->{is_experimental} ? 'experimental' :
                   'core';
        next if $type eq 'experimental' && !$self->{opts}{experimental};
        my $error = $err{$ind->{name}};
        if ($error && ref $error) {
            $error = $self->_dump($error);
        }
        push @{$fails{$type} ||= []}, {
            name => $ind->{name},
            remedy => $ind->{remedy},
            error => $error,
        };
    }

    $res->{fails} = \%fails;
    $res->{score} = $self->score(1);

    return $res->{ok} = (!$fails{core} and (!$fails{extra} || $self->{opts}{core_only})) ? 1 : 0;
}

sub _dump {
    my ($self, $thingy, $pretty) = @_;
    if ($self->{opts}{yaml} && eval { require CPAN::Meta::YAML }) {
        return CPAN::Meta::YAML::Dump($thingy);
    } elsif ($self->{opts}{json} && eval { require JSON::PP }) {
        my $coder = JSON::PP->new->utf8;
        $coder->pretty if $pretty;
        return $coder->encode($thingy);
    } else {
        require Data::Dumper;
        my $dumper = Data::Dumper->new([$thingy])->Terse(1)->Sortkeys(1);
        $dumper->Indent(0) unless $pretty;
        $dumper->Dump;
    }
}

sub stash  { shift->{mca}->d }
sub result { shift->{res} }

sub score {
    my ($self, $wants_detail) = @_;

    my $mca = $self->{mca};
    my %fails = %{$self->{res}{fails} || {}};
    my $max_core_kw = $mca->mck->available_kwalitee;
    my $max_kw = $mca->mck->total_kwalitee;
    my $total_kw = $max_kw - @{$fails{core} || []} - @{$fails{extra} || []};

    my $score = sprintf "%.2f", 100 * $total_kw/$max_core_kw;

    if ($wants_detail) {
        $score .= "% ($total_kw/$max_core_kw)";
    }
    $score;
}

sub report {
    my $self = shift;

    # shortcut
    if ($self->{opts}{dump}) {
        return $self->_dump($self->stash, 'pretty');
    } elsif ($self->{opts}{colour} && $self->_supports_colour) {
        return $self->_colour;
    }

    my $res = $self->{res} || {};

    my $report =
        "Checked dist: $res->{dist}\n" .
        "Score: $res->{score}\n";

    if ($res->{ignored}) {
        $report .= "Ignored metrics: " . join(', ', @{$res->{ignored}}) . "\n";
    }

    if ($res->{ok}) {
        $report .= "Congratulations for building a 'perfect' distribution!\n";
    }
    for my $type (qw/core extra experimental/) {
        if (my $fails = $res->{fails}{$type}) {
            $report .=
                "\n" .
                "Failed $type Kwalitee metrics and\n" .
                "what you can do to solve them:\n\n";
            for my $fail (@$fails) {
                $report .=
                    "Name: $fail->{name}\n" .
                    "Remedy: $fail->{remedy}\n";
                if ($fail->{error}) {
                    $report .= "Error: $fail->{error}\n";
                }
                $report .= "\n";
            }
        }
    }

    $report;
}

sub _supports_colour {
    my $self = shift;
    eval {
        require Term::ANSIColor;
        require Win32::Console::ANSI if $^O eq 'MSWin32';
        1
    }
}

sub _colour_scheme {
    my $self = shift;
    my %scheme = (
        heading => "bright_white",
        title => "blue",
        fail => "bright_red",
        pass => "bright_green",
        warn => "bright_yellow",
        error => "red",
        summary => "blue",
    );
    if ($^O eq 'MSWin32') {
        $scheme{$_} =~ s/bright_// for keys %scheme;
    }
    \%scheme;
}

sub _colour {
    my ($self) = @_;
    my $scheme = $self->_colour_scheme;
    my $icon = $^O eq 'MSWin32'
        ? {pass => 'o', fail => 'x'}
        : {pass => "\x{2713}", fail => "\x{2717}"};

    my $report = Term::ANSIColor::colored("Distribution: ", "bold $scheme->{heading}")
        . Term::ANSIColor::colored($self->result->{dist}, "bold $scheme->{title}")
        . "\n";
    
    my %failed;
    for my $arr (values %{$self->result->{fails}}) {
        for my $fail (@$arr) {
            $failed{$fail->{name}} = $fail;
        }
    }
    
    my $core_fails = 0;
    for my $type (qw/ Core Optional Experimental /) {
        $report .= Term::ANSIColor::colored("\n$type\n", "bold $scheme->{heading}");
        my @inds = $self->{mca}->mck->get_indicators(lc $type);
        my @fails;
        for my $ind (@inds) {
            if ($failed{ $ind->{name} }) {
                push @fails, $ind;
                $core_fails++ if $type eq 'Core';
                $report .= Term::ANSIColor::colored("  $icon->{fail} ", $scheme->{fail}) . $ind->{name};
                $report .= ": " . Term::ANSIColor::colored($failed{ $ind->{name} }{error}, $scheme->{error})
                    if $failed{ $ind->{name} }{error};
            } else {
                $report .= Term::ANSIColor::colored("  $icon->{pass} ", $scheme->{pass}) . $ind->{name};
            }
            $report .= "\n";
        }
        
        for my $fail (@fails) {
            $report .= "\n"
                . Term::ANSIColor::colored("Name:   ", "bold $scheme->{summary}")
                . Term::ANSIColor::colored("$fail->{name}\n", $scheme->{summary})
                . Term::ANSIColor::colored("Remedy: ", "bold $scheme->{summary}")
                . Term::ANSIColor::colored("$fail->{remedy}\n", $scheme->{summary});
        }
    }
    
    my $scorecolour = $scheme->{pass};
    $scorecolour = $scheme->{warn} if keys %failed;
    $scorecolour = $scheme->{fail} if $core_fails;
    
    $report .= "\n"
        . Term::ANSIColor::colored("Score: ", "bold $scheme->{heading}")
        . Term::ANSIColor::colored($self->result->{score}, "bold $scorecolour")
        . "\n";
    
    $report;
}

sub output_report {
    my $self = shift;
    if ($self->{opts}{save}) {
        my $file = $self->report_file;
        open my $fh, '>:utf8', $file or croak "Cannot write to $file: $!";
        print $fh $self->report;
    } else {
        binmode(STDOUT, ':utf8');
        print $self->report;
    }
}

sub report_file {
    my $self = shift;
    my $dir = $self->{opts}{dir} || '.';
    my $vname = $self->{mca}->d->{vname};
    if (!$vname) {
        require File::Basename;
        $vname = File::Basename::basename($self->{res}{dist});
    }
    my $extension =
        $self->{opts}{yaml} ? '.yml' :
        $self->{opts}{json} ? '.json' :
        $self->{opts}{dump} ? '.dmp' :
        '.txt';

    require File::Spec;
    File::Spec->catfile($dir, "$vname$extension");
}

1;

__END__

=encoding utf-8

=head1 NAME

App::CPANTS::Lint - front-end to Module::CPANTS::Analyse

=head1 SYNOPSIS

    use App::CPANTS::Lint;

    my $app = App::CPANTS::Lint->new(verbose => 1);
    $app->lint('path/to/Foo-Dist-1.42.tgz') or print $app->report;

    # if you need raw data
    $app->lint('path/to/Foo-Dist-1.42.tgz') or return $app->result;

    # if you need to look at the details of analysis
    $app->lint('path/to/Foo-Dist-1.42.tgz');
    print Data::Dumper::Dumper($app->stash);

=head1 DESCRIPTION

L<App::CPANTS::Lint> is a core of C<cpants_lint.pl> script to check the Kwalitee of a distribution. See the script for casual usage. You can also use this from other modules for finer control.

=head1 METHODS

=head2 new

Takes an optional hash (which will be passed into L<Module::CPANTS::Analyse> internally) and creates a linter object.

Available options are:

=over 4

=item verbose

Makes L<Module::CPANTS::Analyse> verbose. False by default.

=item core_only

If true, the C<lint> method (see below) returns true even if C<extra> metrics (as well as C<experimental> metrics) fail. This may be useful if you only care Kwalitee rankings. False by default.

=item experimental

If true, failed C<experimental> metrics are also reported (via C<report> method). False by default. Note that C<experimental> metrics are not taken into account while calculating a score.

=item save

If true, C<output_report> method writes to a file instead of writing to STDOUT.

=item dump, yaml, json

If true, C<report> method returns a formatted dump of the stash (see below).

=item search_path

If you'd like to use extra metrics modules, pass a reference to an array of their parent namespace(s) to search. Metrics modules under Module::CPANTS::Kwalitee namespace are always used.

=back

=head2 lint

Takes a path to a distribution tarball and analyses it. Returns true if the distribution has no significant issues (experimental metrics are always ignored). Otherwise, returns false.

Note that the result doesn't always match with what is shown at the CPANTS website, because there are metrics that are only available at the site for various reasons (some of them require database connection, and some are not portable enough).

=head2 report

Returns a report string that contains the details of failed metrics (even if C<lint> method returns true) and a Kwalitee score.

If C<dump> (or C<yaml>, C<json>) is set when you create an App::CPANTS::Lint object, C<report> returns a formatted dump of the stash.

=head2 result

Returns a reference to a hash that contains the details of failed metrics and a Kwalitee score. Internal structure may change without notice, but it always has an "ok" field (which holds a return value of C<lint> method) at least.

=head2 stash

Returns a reference to a hash that contains the details of analysis (stored in a stash in L<Module::CPANTS::Analyse>). Internal structure may change without notice, but it always has a "kwalitee" field (which holds a reference to a hash that contains the result of each metric) at least.

=head2 score

Returns a Kwalitee score.

=head2 output_report

Writes a report to STDOUT (or to a file).

=head2 report_file

Returns a path to a report file, which should have the same distribution name with a version, plus an extension appropriate to the output format. (eg. C<Foo-Bar-1.42.txt>, C<Foo-Bar-1.42.yml> etc)

=head1 SEE ALSO

L<Module::CPANTS::Analyse>

L<Test::Kwalitee>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
