package DBIx::SchemaChecksum::App::ShowUpdatePath;
use 5.010;

# ABSTRACT: DBIx::SchemaChecksum command show_update_path

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);
use Carp qw(croak);

option 'from_checksum'  => ( is => 'ro', isa => 'Str' );
option 'output'  => ( is => 'ro', isa => 'Str', default=>'nice'); # todo enum
option 'dbname' => ( is=>'ro', isa=>'Str', default=>'datebase_name');
option '+sqlsnippetdir' => ( required => 1);

has '_concat' => (is=>'rw',isa=>'Str', default=>'');

sub run {
    my $self = shift;

    $self->show_update_path( $self->from_checksum || $self->checksum );

    if ($self->output eq 'concat') {
        say $self->_concat;
    }
}

sub show_update_path {
    my ($self, $this_checksum) = @_;
    my $update_path = $self->_update_path;

    my $update = $update_path->{$this_checksum}
        if ( exists $update_path->{$this_checksum} );

    unless ($update) {
        say "No update found that's based on $this_checksum.";
        return;
    }

    if ( $update->[0] eq 'SAME_CHECKSUM' ) {
        my ( $file, $post_checksum ) = splice( @$update, 1, 2 );
        $self->report_file($file, $post_checksum);
        $self->show_update_path($post_checksum);
    }
    else {
        $self->report_file($update->[0],$update->[1]);
        $self->show_update_path($update->[1]);
    }
}

sub report_file {
    my ($self, $file, $checksum) = @_;

    if ($self->output eq 'nice') {
        say $file->relative($self->sqlsnippetdir) ." ($checksum)";
    }
    elsif ($self->output eq 'script') {
        say 'psql '.$self->dbname.' -1 -f '.$file->relative($self->sqlsnippetdir);
    }
    elsif ($self->output eq 'concat') {
        $self->_concat( $self->_concat
        . "\n\n-- file: ".$file->relative($self->sqlsnippetdir)."\n".join('',$file->slurp)."\n" );
    }
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::App::ShowUpdatePath - DBIx::SchemaChecksum command show_update_path

=head1 VERSION

version 1.006

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
