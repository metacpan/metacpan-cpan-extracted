package App::RL::Command::compare;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

sub abstract {
    return 'compare 2 chromosome runlists';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename. [stdout] for screen" ],
        [ "op=s",     "operations: intersect, union, diff or xor", { default => "intersect" } ],
        [ "remove|r", "remove 'chr0' from chromosome names" ],
        [ "mk",       "*first* YAML file contains multiple sets of runlists" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist compare [options] <infile1> <infile2> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 2 ) {
        my $message = "This command need two or more input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( $opt->{op} =~ /^dif/i ) {
        $opt->{op} = 'diff';
    }
    elsif ( $opt->{op} =~ /^uni/i ) {
        $opt->{op} = 'union';
    }
    elsif ( $opt->{op} =~ /^int/i ) {
        $opt->{op} = 'intersect';
    }
    elsif ( $opt->{op} =~ /^xor/i ) {
        $opt->{op} = 'xor';
    }
    else {
        Carp::confess "[@{[$opt->{op}]}] invalid\n";
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . "." . $opt->{op} . ".yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $chrs = Set::Scalar->new;

    # file1
    my $set_of = {};
    my @names;
    if ( $opt->{mk} ) {
        my $yml = YAML::Syck::LoadFile( $args->[0] );
        @names = sort keys %{$yml};

        for my $name (@names) {
            $set_of->{$name} = App::RL::Common::runlist2set( $yml->{$name}, $opt->{remove} );
            $chrs->insert( keys %{ $set_of->{$name} } );
        }
    }
    else {
        @names = ("__single");
        $set_of->{__single}
            = App::RL::Common::runlist2set( YAML::Syck::LoadFile( $args->[0] ), $opt->{remove} );
        $chrs->insert( keys %{ $set_of->{__single} } );
    }

    # file2 and more
    my @set_singles;
    {
        my $argc = scalar @{$args};
        for my $i ( 1 .. $argc - 1 ) {
            my $s = App::RL::Common::runlist2set( YAML::Syck::LoadFile( $args->[$i] ),
                $opt->{remove} );
            $chrs->insert( keys %{$s} );
            push @set_singles, $s;
        }
    }

    #----------------------------#
    # Operating
    #----------------------------#
    my $op_result_of = { map { $_ => {} } @names };

    for my $name (@names) {
        my $set_one = $set_of->{$name};

        # give empty set to non-existing chrs
        for my $s ( $set_one, @set_singles ) {
            for my $chr ( sort $chrs->members ) {
                if ( !exists $s->{$chr} ) {
                    $s->{$chr} = App::RL::Common::new_set();
                }
            }
        }

        # operate on each chr
        for my $chr ( sort $chrs->members ) {
            my $op     = $opt->{op};
            my $op_set = $set_one->{$chr}->copy;
            for my $s (@set_singles) {
                $op_set = $op_set->$op( $s->{$chr} );
            }
            $op_result_of->{$name}{$chr} = $op_set->runlist;
        }
    }

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    if ( $opt->{mk} ) {
        print {$out_fh} YAML::Syck::Dump($op_result_of);
    }
    else {
        print {$out_fh} YAML::Syck::Dump( $op_result_of->{__single} );
    }

    close $out_fh;
}

1;
