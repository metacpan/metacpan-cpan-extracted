package App::Git::Workflow::Command::Memo;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use Pod::Usage;
use Term::ANSIColor qw/colored/;
use JSON qw/decode_json encode_json/;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.20);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %p2u_extra;
our %option;
our %cmd_map = (
    ( map { $_ => $_ } qw/add list switch delete/ ),
    ls => 'list',
    rm => 'delete',
    sw => 'switch',
);

sub run {
    my ($self) = @_;

    get_options( \%option, 'commitish|c=s', 'number|n=i', 'force|f!',
        'verbose|v+' );

    my $action = 'do_' . ( $cmd_map{ $ARGV[0] || 'add' } || '' );

    if ( !$self->can($action) ) {
        warn "Unknown action $ARGV[0]!\n";
        Pod::Usage::pod2usage( %p2u_extra, -verbose => 1 );
        return 1;
    }

    $self->$action();
}

sub do_add {
    my ($self) = @_;
    my $memo = $self->get_memos();

    my $commitish
        = $option{commitish}
        || $ARGV[-1]
        || $workflow->git->rev_parse( '--abbrev-ref', 'HEAD' );
    chomp $commitish;

    $memo->{names}{$commitish} = {
        date => time,
        sha => $workflow->git->log( '-n1', '--format=format:%H', $commitish ),
    };

    $self->set_memos($memo);
}

sub commit_name {
    my ( $self, $memo, $type ) = @_;
    my $name;
    $option{number} //= pop @ARGV;

    if ( $option{commitish} && $memo->{names}{ $option{commitish} } ) {
        $name = $option{commitish};
    }
    elsif ( $option{number} eq $type ) {
        warn "git memo $type requires an argument!\n";
        Pod::Usage::pod2usage( %p2u_extra, -verbose => 1 );
        return;
    }
    elsif ( defined $option{number} ) {
        my $i = 0;
        for my $memo_item ( sort keys %{ $memo->{names} } ) {
            if ( $i++ == $option{number} ) {
                $name = $memo_item;
                last;
            }
        }
    }

    die "No branch/tag/commit found matching "
        . ( $option{number} || $option{commitish} ) . "!\n"
        if !$name;

    return $name;
}

sub do_delete {
    my ($self) = @_;
    my $memo = $self->get_memos();

    my $name = $self->commit_name( $memo, 'delete' );
    return if !$name;
    delete $memo->{names}{$name};

    $self->set_memos($memo);
}

sub do_switch {
    my ($self) = @_;
    my $memo = $self->get_memos();

    my $name = $self->commit_name( $memo, 'switch' );
    return if !$name;
    $workflow->git->checkout($name);

    $memo->{last} = $name;
    $self->set_memos($memo);

    $self->do_list();
}

sub do_list {
    my ($self)  = @_;
    my $memo    = $self->get_memos();
    my $i       = 0;
    my $max     = int( log( keys %{ $memo->{names} } ) / log(10) ) + 1;
    my $current = $workflow->git->rev_parse( '--abbrev-ref', 'HEAD' );
    chomp $current;
    my $sha = $workflow->git->log( '-n1', '--format=format:%H', $current );

    for my $memo_item ( sort keys %{ $memo->{names} } ) {
        my $marker
            = $memo_item eq $current                  ? '*'
            : $memo_item eq $memo->{last}             ? '#'
            : $memo->{names}{$memo_item}{sha} eq $sha ? '-'
            :                                           ' ';
        my $date = '';
        if ( $option{verbose} ) {
            my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
                = localtime( $memo->{names}{$memo_item}{date} );
            $mon++;
            $year += 1900;
            $date = sprintf "%04i-%02i-%02i %02i:%02i:%02i ", $year,
                $mon, $mday, $hour, $min, $sec;
        }

        printf "[%${max}i] %s%s %s\n", $i++, $date, $marker, $memo_item;
    }
}

sub set_memos {
    my ( $self, $json ) = @_;
    my $git_dir = $workflow->git->rev_parse("--show-toplevel");
    chomp $git_dir;
    my $memo = "$git_dir/.git/memo.json";

    open my $fh, '>', $memo or die "Can't write to $memo: $!";

    print {$fh} encode_json($json), "\n";
}

sub get_memos {
    my ($self) = @_;
    my $git_dir = $workflow->git->rev_parse("--show-toplevel");
    chomp $git_dir;
    my $memo = "$git_dir/.git/memo.json";

    if ( !-f $memo ) {
        return { last => '', names => {} };
    }

    open my $fh, '<', $memo or die "Can't open $memo: $!";
    my $json_text = join '', <$fh>;

    my $json = decode_json($json_text);

    $json->{last} ||= '';
    return $json;
}

1;

__DATA__

=head1 NAME

git-memo - Help Memo many commits

=head1 VERSION

This documentation refers to git-memo version 1.1.20

=head1 SYNOPSIS

   git-memo [add] [(-c|--commitish)[=]sha|branch|tag]
   git-memo (list|ls)
   git-memo (switch|sw) (-n|--number) number
   git-memo (delete|rm) (-n|--number) number [--force|-f]

 SUB-COMMAND:
  add           Add either the current branch/commit/etc or a specified commitish to the memo list
  list          List all memoed commitishes
  switch        Switch to a saved memoed commitish
  delete        Delete a saved memoed commitish

 OPTIONS:
  -c --commitish[=]sha|branch|tag
                The specified commit to add to the memo list
  -n --number[=]int
                A memoed commitish to switch to

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-memo

=head1 DESCRIPTION

Memo current branch, commit or tag to make finding them easier in the future.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
