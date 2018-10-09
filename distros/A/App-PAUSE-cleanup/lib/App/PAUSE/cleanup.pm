package App::PAUSE::cleanup;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Manage (delete/undelete) your PAUSE files
$App::PAUSE::cleanup::VERSION = '0.0014';
use strict;
use warnings;

use Getopt::Usaginator <<_END_;

Usage: pause-cleanup <options>

    --username <username>   Your PAUSE username
    --password <password>   The password for the above
                            Instead of supplying your identity on the
                            commandline, you can setup \$HOME/.pause like so:

                                user <username>
                                password <password>

    -d, --dump              Dump the list of files to STDOUT
    
    -h, -?, --help          This help

_END_
use Getopt::Long qw/ GetOptions /;


use Term::EditorEdit;
use Config::Identity::PAUSE;
use WWW::Mechanize;
use Web::Query 'wq';


my $agent = WWW::Mechanize->new;

sub run {
    my $self = shift;
    my @arguments = @_;

    my ( $help, $username, $password, $dump );
    {  
        local @ARGV = @arguments;
        GetOptions(
            'username=s' => \$username,
            'password=s' => \$password,
            'dump|d' => \$dump,
            'help|h|?' => \$help,
        );
    }

    usage 0 if $help;

    my %identity = Config::Identity::PAUSE->load;
    $username = $identity{user} unless defined $username;
    $password = $identity{password} unless defined $password;

    usage '! Missing username and/or password' unless
        defined $username && defined $password;

    $agent->credentials( "pause.perl.org:443", "PAUSE", $username, $password );

    print "> Logging in as $username\n";
    
    my $response = $agent->get( 'https://pause.perl.org/pause/authenquery?ACTION=delete_files' );

    my @filelist = $self->parse_filelist( $response->decoded_content );

    if ( $dump ) {
        print join "\n", map { $_->{package_version} } @filelist;
        print "\n";
        return;
    }

    my %package;
    for my $file (@filelist) {
        push @{ $package{$file->{package}} }, $file;
    }

    my @document;
    push @document, <<_END_;
# Logged in as $username
#
# Any line not beginning with 'delete', 'undelete', or 'keep' is ignored
# To take action on a release, remove the leading '#'
#   
#   delete      Delete the .meta, .readme, and .tar.gz associated
#               with the release
#
#   undelete    Undelete the .meta, .readme, and .tar.gz (remove
#               from scheduled deletion
#
#   keep        Ignore the release
#
# By default, the latest version of each release is commented 'keep'
# Older versions are commented 'delete' (or 'undelete')
_END_

    for my $name (sort keys %package) { 
        my @filelist = @{ $package{$name} };
        @filelist = sort { $a->{scheduled} cmp $b->{scheduled} or
                           $b->{tar_gz} cmp $a->{tar_gz} } @filelist;

        push @document, "$name:";

        my @latest = $self->extract_latest( \@filelist );

        for my $latest ( @latest ) {
            if ( $latest->{scheduled} )
                    { push @document, "# undelete $latest->{package_version}" }
            else    { push @document, "# keep $latest->{package_version}" }
        }

        push @document,
            ( map {
                my $operation = $_->{scheduled} ? "undelete" : "delete";
                "# $operation $_->{package_version}"
            } @filelist ),
            '',
        ;
    }

    my $document = join "\n", @document;
    
    my $delete_undelete = Term::EditorEdit->edit( document => $document, process => sub {
        my $edit = shift;
        my ( @delete, @undelete );
        my @content = split m/\n/, $edit->content;
        for my $line ( @content ) {
            next unless $line =~ m/^\s*(delete|undelete)\s*(\S+)/i;
            if ( lc $1 eq 'delete' ) { push @delete, $2 }
            else                     { push @undelete, $2 }
        }
        return { delete => \@delete, undelete => \@undelete };
    } );

    my ( $delete, $undelete ) = @$delete_undelete{qw/ delete undelete /}; 

    if ( @$delete ) {
        print "\n---\n";
        print join "\n", '', ( map { " $_" } @$delete ), '', '';
        print "> Really delete? If you wish to abort, hit ^C (CTRL-C) now!\n";
        print "> Hit return to continue, or cancel with ^C\n";
        my $nil = <STDIN>;
        my $count = scalar @$delete;
        print "> Deleting $count\n";
        $self->_delete( $delete );
    }
    
    if ( @$undelete ) {
        print "\n---\n";
        print join "\n", '', ( map { " $_" } @$undelete ), '', '';
        my $count = scalar @$undelete;
        print "> Undeleting $count\n";
        $self->_undelete( $undelete );
    }

    unless ( @$delete || @$undelete ) {
        print "> Nothing to do\n";
    }
}

sub parse_filelist {
    my( $self, $document ) = @_;

    @{ wq($document)->find('input[name="pause99_delete_files_FILE"]')->map(sub{
        my $tr = $_->parent->parent;
        my $file = $tr->find('.file')->text;

        my $package = $file;
        $package =~ s/-([\d\._]+)\.tar\.gz$//
            or return ();
        my $version = $1;

        return {
            tar_gz          => $file,
            package         => $package,
            package_version => join( '-', $package, $version ),
            version         => $version,
            size            => $tr->find('.size')->text,
            scheduled       => !!($tr->find('.modified') =~ /Scheduled for deletion/),
        };
    }) };


}

sub _delete {
    my $self = shift;
    $self->_submit( 'SUBMIT_pause99_delete_files_delete', @_ );
}

sub _undelete {
    my $self = shift;
    $self->_submit( 'SUBMIT_pause99_delete_files_undelete', @_ );
}

sub extract_latest {
    my $self = shift;
    my $filelist = shift;

    my @latest;
    my @filelist;
    my $found;

    for my $file ( @$filelist ) {
        if ( $file->{version} =~ m/_/ ) {
            if ( ! @latest )    { push @latest, $file }
            else                { push @filelist, $file }
        }
        elsif ( ! $found ) {
            $found = 1;
            push @latest, $file;
        }
        else {
            push @filelist, $file;
        }
    }

    @$filelist = @filelist;
    return @latest;
}

sub expand_filelist {
    my $self = shift;
    my $filelist = shift; # Actually, package_version

    my @filelist;
    for my $package_version (@$filelist) {
        my $pv = $package_version;
        my ( $version ) = $pv =~ m/-([\d\._]+)$/;
        if ( $version =~ m/_/ )
                { push @filelist, "$pv.tar.gz" }
        else    { push @filelist, map { ( "$_.meta", "$_.readme", "$_.tar.gz" ) } $pv }
    }

    return @filelist;
}

sub _submit {
    my $self = shift;
    my $button = shift;
    my $filelist = shift; # Actually, package_version
    
    my @filelist = $self->expand_filelist( $filelist );
    $agent->get( 'https://pause.perl.org/pause/authenquery?ACTION=delete_files' );
    $agent->tick( 'pause99_delete_files_FILE' => $_ ) for @filelist;
    $agent->click( $button );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PAUSE::cleanup - Manage (delete/undelete) your PAUSE files

=head1 VERSION

version 0.0014

=head1 SYNOPSIS

    $ pause-cleanup

    $ pause-cleanup -?

=head1 DESCRIPTION

C<pause-cleanup> is a tool for managing the files in your PAUSE account. Run from the commandline, it will launch C<$EDITOR> (or C<$VISUAL>) with an editable document containing the state of your account. By editing the document you can delete or undelete files

=head1 USAGE

    Usage: pause-cleanup <options>

        --username <username>   Your PAUSE username
        --password <password>   The password for the above
                                Instead of supplying your identity on the
                                commandline, you can setup \$HOME/.pause like so:

                                    user <username>
                                    password <password>

        -d, --dump              Dump the list of files to STDOUT
        
        -h, -?, --help          This help

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
