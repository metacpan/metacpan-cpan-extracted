package DataFlow::Proc::DBF;

use warnings;
use strict;

our $VERSION = '0.03';

use Moose;
use MooseX::Aliases;
extends 'DataFlow::Proc::Converter';

use XBase;
use File::Temp qw(:seekable);
use File::Spec ();
use autodie;
use namespace::autoclean;

has '+converter' => (
    lazy    => 1,
    default => sub { return XBase->new },
    handles => {
        dbf          => sub { shift->converter(@_)      },
        dbf_opts     => sub { shift->converter_opts(@_) },
        has_dbf_opts => sub { shift->has_converter_opts },
    },
    init_arg => 'dbf',
);

has '+converter_opts' => ( 'init_arg' => 'dbf_opts', );

has 'header' => (
    'is'        => 'rw',
    'isa'       => 'ArrayRef[Maybe[Str]]',
    'predicate' => 'has_header',
    'alias'     => 'headers',
    'handles'   => { 'has_headers' => sub { shift->has_header }, },
);


 
has 'header_wanted' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'lazy'    => 1,
    'default' => sub {
        my $self = shift;
        return 0 if $self->direction eq 'CONVERT_FROM';
        return $self->has_header;
    },
);


sub _policy {
    return shift->direction eq 'CONVERT_TO' ? 'ArrayRef' : 'Scalar';
}

sub _build_subs {
    my $self = shift;
    return {
        'CONVERT_TO' => sub {
            my $data = $_;
            my $options = $self->has_converter_opts
                        ? $self->converter_opts : {}
                        ;

            unless (exists $options->{'name'}) {
                $options->{'dir'}  = File::Temp->newdir( CLEANUP => 1 );
                $options->{'name'} = File::Spec->catfile($options->{'dir'}, 'tmp.dbf');
            }

            # header is mandatory, so we either
            # use one provided by the user,
            # or create our own "fake" version
            my $field_names;
            if ($self->header_wanted) {
                $self->header_wanted(0);
                $field_names = $self->header;
            }
            else {
                push @$field_names, "item$_"
                    foreach ( 0 .. $#{ $data->[0] } );
            }

            my $table = $self->converter->create(
                name           => $options->{'name'},
                field_names    => $field_names,
                field_types    => [],
                field_lengths  => [],
                field_decimals => [],
            ) or die 'error creating DBF: ' . $self->converter->errstr;

            foreach my $i ( 0 .. $#{$data} ) {
                $table->set_record($i, @{ $data->[$i] } );
            }

            $table->close;

            # temporary DBF file saved. Get the content back
            open my $fh, '<', $options->{'name'};
            binmode $fh;
            my $content = do { local $/; <$fh> };
            return $content;
        },

        'CONVERT_FROM' => sub {
            my $string = $_;
            my $options = $self->has_converter_opts
                        ? $self->converter_opts : {}
                        ;

            my $dbf;

            # if the user passes a file name or handle
            # to read from, we use it. Otherwise, we
            # assume the DBF is in a binary string 
            # (the "flow") and make our interface with
            #  XBase using a temp file
            my $fh;
            unless (exists $options->{'name'} or exists $options->{'fh'}) {
                $fh = File::Temp->new( UNLINK => 1 );
                binmode $fh;
                print $fh $string;
                close $fh;

                $options->{name} = $fh->filename;
            }

            $dbf = $self->converter;
            $dbf->open( %$options )
                or die XBase->errstr;

            my $records = $dbf->get_all_records;

            if ($self->header_wanted) {
                $self->header_wanted(0);
                $self->header( [$dbf->field_names] );
            }

            $dbf->close;
            return $records;
        },
    };
}

__PACKAGE__->meta->make_immutable;

42;
__END__

=head1 NAME

DataFlow::Proc::DBF - A dBase DBF converting processor


=head1 SYNOPSIS

    use DataFlow;

    # creating our flow
    my $flow = DataFlow->new([
       [ 'DBF' => { direction => 'CONVERT_FROM' } ],
    ]);


    # getting back a perl arrayref
    my $perl_struct = $flow->process( $slurped_dbf_data );


  
=head1 DESCRIPTION

This module provides a processing step for dBase (DBF) files under
L<DataFlow>. It lets you C<CONVERT_FROM> a DBF file into a Perl
data structure (in this case, an array reference) and C<CONVERT_TO>
a DBF stream, from a Perl array reference (the stream can be saved
into a file for later inspection with dBase).

=head1 OPTIONS

=head2 direction

=over 4

=item * CONVERT_FROM

Converts FROM a DBF stream or file into a Perl array reference.

=item * CONVERT_TO

Converts TO a a DBF stream or file, from a Perl array reference.

=back

=head2 header_wanted

Saves the header of the structure into C<< $proc->header >>. You can
reach it via C<< $flow->procs->[ $i ]->header >>, where C<$i> is the
index of the DBF processor in your flow. For example:

  my $flow = DataFlow->new([
      [ 'DBF' => { direction => 'CONVERT_FROM', header_wanted => 1 } ],
  ]);

  my $perl_data = $flow->process( $dbf_data );
  my $header    = $flow->procs->[0]->header;

=head2 dbf_opts

  my $flow = DataFlow->new([
     [ 'DBF' => {
         direction => 'CONVERT_FROM',
         dbf_opts  => { name => 'dbase.dbf' },
       }
     ],
  ]);

Sets any particular option you may want to pass to L<XBase>. The most
important one being B<name>, in which you can specify a file name
for either input (CONVERT_FROM) or output (CONVERT_TO).


=head1 DIAGNOSTICS

=over 4

=item C<< Error creating DBF: $MESSAGE >>

The conversor was unable to create a DBF file with the provided structure.
Make sure you pass a matrix with lines containing the same number of elements.

=back


=head1 CONFIGURATION AND ENVIRONMENT

DataFlow::Proc::DBF requires no configuration files or environment variables.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-dataflow-proc-dbf@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

L<DataFlow>, L<XBase>

=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Breno G. de Oliveira C<< <garu@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
