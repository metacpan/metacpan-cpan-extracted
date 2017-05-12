package DBIx::SchemaChecksum::App::ApplyChanges;
use 5.010;

# ABSTRACT: DBIx::SchemaChecksum command apply_changes

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);
use IO::Prompt::Tiny qw(prompt);
use Try::Tiny;

option '+sqlsnippetdir' => ( required => 1);
option 'dry_run'        => ( is => 'rw', isa => 'Bool', default => 0 );
has 'no_prompt'    => ( is => 'rw', isa => 'Bool', default => 0, documentation=>'Do not prompt, just use defaults');

sub run {
    my $self = shift;

    $self->apply_sql_snippets($self->checksum);
}


sub apply_sql_snippets {
    my ($self,  $this_checksum ) = @_;
    my $update_path = $self->_update_path;

    my $update = $update_path->{$this_checksum}
        if ( exists $update_path->{$this_checksum} );

    unless ($update) {
        foreach my $update_entry (values %{$update_path}) {
            my $post_checksum_index = 0;
            while (@{$update_entry} > $post_checksum_index) {
                if ($update_entry->[$post_checksum_index] eq 'SAME_CHECKSUM') {
                    $post_checksum_index++;
                    next;
                }
                if ($update_entry->[$post_checksum_index+1] eq $this_checksum) {
                    say "db checksum $this_checksum matching ".$update_entry->[$post_checksum_index]->relative;
                    return;
                }
                $post_checksum_index += 2;
            }
        }
        say "No update found that's based on $this_checksum.";
        return;
    }

    if ( $update->[0] eq 'SAME_CHECKSUM' ) {
        return unless $update->[1];
        my ( $file, $expected_post_checksum ) = splice( @$update, 1, 2 );

        $self->apply_file( $file, $expected_post_checksum );
    }
    else {
        $self->apply_file( @$update );
    }
}

sub apply_file {
    my ( $self, $file, $expected_post_checksum ) = @_;
    my $filename = $file->relative($self->sqlsnippetdir);

    my $no_checksum_change = $self->checksum eq $expected_post_checksum ? 1 : 0;

    my $answer;
    if ($no_checksum_change) {
        $answer = prompt("Apply $filename (won't change checksum)? [y/n/s]",'y');
    }
    else {
        $answer = prompt("Apply $filename? [y/n]",'y');
    }

    if ($answer eq 'y') {
        say "Starting to apply $filename" if $self->verbose;

        my $content = $file->slurp;

        my $dbh = $self->dbh;
        $dbh->begin_work;

		my $split_regex = qr/(?!:[\\]);/;

		if ($content =~ m/--\s*split-at:\s*(\S+)\n/s) {
			say "Splitting $filename commands at >$1<";
			$split_regex = qr/$1/;
		}

        $content =~ s/^\s*--.+$//gm;
        foreach my $command ( split( $split_regex , $content ) ) {
            $command =~ s/\A\s+//;
            $command =~ s/\s+\Z//;

            next unless $command;
            say "Executing SQL statement: $command" if $self->verbose;
            my $success = try {
                $dbh->do($command);
                return 1;
            }
            catch {
                $dbh->rollback;
                say "SQL error: $_" unless $dbh->{PrintError};
                say "ABORTING!";
                return undef;
            };
            return unless $success; # abort all further changes
            say "Successful!" if $self->verbose;
        }

        if ( $self->dry_run ) {
            $dbh->rollback;
            say "dry run, so checksums cannot match. We proceed anyway...";
            return $self->apply_sql_snippets($expected_post_checksum);
        }

        # new checksum
        $self->reset_checksum;
        my $post_checksum = $self->checksum;

        if ( $post_checksum eq $expected_post_checksum ) {
            say "post checksum OK";
            $dbh->commit;
            if ($self->_update_path->{$post_checksum}) {
                return $self->apply_sql_snippets($post_checksum);
            }
            else {
                say 'No more changes';
                return;
            }
        }
        else {
            say "post checksum mismatch!";
            say "  expected $expected_post_checksum";
            say "  got      $post_checksum";
            $dbh->rollback;
            say "ABORTING!";
            return;
        }
    }
    elsif ($answer eq 's') {
        return $self->apply_sql_snippets($expected_post_checksum);
    }
    else {
        say "Not applying $filename, so we stop.";
        return;
    }
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::App::ApplyChanges - DBIx::SchemaChecksum command apply_changes

=head1 VERSION

version 1.006

=head1 METHODS

=head2 apply_sql_snippets

    $self->apply_sql_snippets( $starting_checksum );

Applies SQL snippets in the correct order to the DB. Checks if the
checksum after applying the snippets is correct. If it isn't correct
rolls back the last change (if your DB supports transactions...)

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Maroš Kollár <maros@cpan.org>

=item *

Klaus Ita <koki@worstofall.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
