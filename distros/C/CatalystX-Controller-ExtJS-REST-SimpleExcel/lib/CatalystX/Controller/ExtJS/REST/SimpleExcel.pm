#
# This file is part of CatalystX-Controller-ExtJS-REST-SimpleExcel
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Controller::ExtJS::REST::SimpleExcel;
BEGIN {
  $CatalystX::Controller::ExtJS::REST::SimpleExcel::VERSION = '0.1.1';
}
# ABSTRACT: Serialize to Excel spreadsheets
use Moose::Role -traits => 'CatalystX::Controller::ExtJS::REST::SimpleExcel::Trait';
use strict;
use warnings;
use JSON::XS ();

after list => sub {
    my ($self, $c) = @_;
    return unless($c->request->accepts('application/vnd.ms-excel'));
    my $data = $c->stash->{$self->config->{stash_key}};
    my @header = map { $_->{mapping} } @{$data->{metaData}->{fields}};
    my @rows;
    foreach my $row(@{$data->{$self->root_property}}) {
        my @row;
        foreach my $head(@header) {
            my $rcopy = $row;
            my $hcopy = $head;
            while($hcopy =~ s/^(\w+)\.//) {
                $rcopy = $rcopy->{$1};
            }
            push(@row, ref $rcopy->{$hcopy} ? JSON::XS::encode_json($rcopy->{$hcopy}) : $rcopy->{$hcopy} );
        }
        push(@rows, \@row);
    }
    $c->stash->{$self->config->{stash_key}} = {
        sheets => [{
            name => $self->default_resultset,
            header => \@header,
            rows => \@rows
        }]
    };
};

1;



=pod

=head1 NAME

CatalystX::Controller::ExtJS::REST::SimpleExcel - Serialize to Excel spreadsheets

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

 package MyApp::Controller::User;
 use Moose;
 extends 'CatalystX::Controller::ExtJS::REST';
 with    'CatalystX::Controller::ExtJS::REST::SimpleExcel';
 
 1;

Access C<< /users?content-type=application%2Fvnd.ms-excel >> to get the excel file.

=head1 DESCRIPTION

This role loads L<Catalyst::Action::Serialize::SimpleExcel> and adds 
C<< application/vnd.ms-excel >> to the type map. When requesting a list of
objects, this role converts the output to satisfy L<Catalyst::Action::Serialize::SimpleExcel>.

=head1 SEE ALSO

L<CatalystX::Controller::ExtJS::REST>

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

