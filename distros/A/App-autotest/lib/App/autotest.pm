use strict;
use warnings;

package App::autotest;
$App::autotest::VERSION = '0.006';
# ABSTRACT: main package for the autotest tool

use Moose;
use File::Find;
use File::Spec;
use Cwd;
use File::ChangeNotify;
use List::MoreUtils;

use App::autotest::Test::Runner;
use App::autotest::Test::Runner::Result::History;

has test_directory => ( is => 'rw', isa => 'Str', default => 't' );

has watcher => (
    is      => 'rw',
    isa     => 'File::ChangeNotify::Watcher',
    default => sub {
        File::ChangeNotify->instantiate_watcher(
            directories => ['t', 'lib'],
            filter      => qr/(?:\.t|\.pm)$/,
        );
    }
);

has after_change_or_new_hook => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { 0 }
    }
);

has history => ( is => 'rw',
    default => sub { App::autotest::Test::Runner::Result::History->new } );

has test_runner => ( is => 'rw',
    default => sub { App::autotest::Test::Runner->new });

sub run {
    my ($self) = @_;

    $self->run_tests_upon_startup;
    $self->run_tests_upon_change_or_creation;
}

sub run_tests_upon_startup {
    my ($self) = @_;

    my $all_test_programs = $self->all_test_programs( $self->test_directory );

    $self->run_tests(@$all_test_programs);
}

sub run_tests_upon_change_or_creation {
    my ($self) = @_;

    while (1) {

        my $test_files = $self->pm_to_t( $self->changed_and_new_files );
        next unless @$test_files;

        $self->run_tests( @$test_files );

        last if $self->after_change_or_new_hook->();
    }
    return 1;
}

sub pm_to_t {
    my ($self, $change_files) = @_;
    
    my $all_test_programs  = $self->all_test_programs( $self->test_directory );
    my @all_test_parts_map = map { +{ path => $_, parts => $self->break_path($_) } } @$all_test_programs;

    my @test_paths;

    foreach ( @$change_files ) {

        if ( $_ =~ /\.t$/ ) {
            push @test_paths, $_;
            next;
        }

        my $test_path = $self->find_max_rate_of_concordance($self->break_path($_), \@all_test_parts_map);

        if (defined $test_path) {
            push @test_paths, $test_path;
        }
    }

    return \@test_paths;
}

sub find_max_rate_of_concordance {
    my ($self, $file_parts, $all_test_programs) = @_;

    my @sorted_test_data = sort { $a->{rate} <=> $b->{rate} }
                           map  {
                                   +{
                                       path => $_->{path}, 
                                       rate => $self->calc_rate_of_concordance($file_parts, $_->{parts}) 
                                    }
                                }
                                @$all_test_programs;

    return unless @sorted_test_data;

    my $max_data = $sorted_test_data[-1];

    return $max_data->{rate} == 0 ? undef : $max_data->{path};
}

sub calc_rate_of_concordance {
    my ($self, $target_parts, $cmp_parts) = @_;

    return 0 unless ( @$target_parts );

    my %target_map = map { $_ => 1 }  @$target_parts;

    foreach ( @$cmp_parts ) {
        $target_map{$_}++;
    }

    return scalar( grep { $_ >= 2 } values %target_map ) / scalar @$target_parts;
}

sub break_path {
    my ($self, $path) = @_;

    (my $lc_path = $path) =~ s/([A-Z])/_\l$1/g;
    return [ List::MoreUtils::uniq( split(qr/[\\\/\.\-_]/, $lc_path) ) ];
}

sub changed_and_new_files {
    my ($self) = @_;

    my @files;
    for my $event ( $self->watcher->wait_for_events() ) {
        my $type = $event->type();
        my $file_changed = $type eq 'create' || $type eq 'modify';
        push @files, $event->path() if $file_changed;
    }

    return \@files;
}

{
    my @files;

    sub all_test_programs {
        my ($self) = @_;

        @files = ();    # throw away result of last call
        find( { wanted => \&_wanted, no_chdir => 1 },
            './' . $self->test_directory );

        return \@files;
    }

    sub _wanted {
        my $cwd  = getcwd();
        my $name = $File::Find::name;

        push @files, File::Spec->catfile( $cwd, $name ) if $name =~ m{\.t$};
    }

}

sub run_tests {
    my ($self, @tests)=@_;

    my $result=$self->test_runner->run(@tests);
    $self->history->perpetuate($result);

    if ($self->history->things_just_got_better) {
        $self->print("Things just got better.\n");
    }
}

sub print {
    my ($self, @rest)=@_;
    print @rest;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::autotest - main package for the autotest tool

=head1 VERSION

version 0.006

=head1 AUTHOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
