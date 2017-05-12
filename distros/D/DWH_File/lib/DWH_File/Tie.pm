package DWH_File::Tie;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&store_string,
    fallback => 1;

use DWH_File::Cached;
use DWH_File::Reference;

@ISA = qw( DWH_File::Value DWH_File::Cached DWH_File::Reference );
$VERSION = 0.01;

sub perform_tie {
    my ( $this, $kernel, $ref, $id, $tail ) = @_;
    my $class = ref $this || $this;
    my $self = {
        content => $ref,
        kernel => $kernel,
        string_val => '',
        cache_count => 0,
    };
    bless $self, $class;
    $self->{ id } = $id || $kernel->next_id;
    $kernel->tieing( $self );
    if ( defined $id ) { $self->wake_up_call( $tail ) }
    else { $self->sign_in_first_time }
    $kernel->did_tie( $self );
    return $self;
}

# template methods
sub wake_up_call {} # param: tail
sub sign_in_first_time {}
sub custom_grounding { '' };

# overridden method from DWH_File::Value
sub actual_value { $_[ 0 ]->{ content } }

sub store_string {
    $_[ 0 ]->{ string_val } ||= $_[ 0 ]->{ kernel }->
                                reference_string( $_[ 0 ] );
}

sub cache_key { $_[ 0 ]->{ id } }

sub cache_up { $_[ 0 ]->{ cache_count }++ }

sub cache_down {
    $_[ 0 ]->{ cache_count }--;
    $_[ 0 ]->{ cache_count } or $_[ 0 ]->cache_out;
}

sub cache_out {}

sub bump_refcount {
    $_[ 0 ]->{ kernel }->bump_refcount( $_[ 0 ]->{ id } );
}

sub cut_refcount {
    $_[ 0 ]->{ kernel }->cut_refcount( $_[ 0 ]->{ id } );
}

sub DESTROY {
    %{ $_[ 0 ] } = ();
}

1;

__END__

=head1 NAME

DWH_File::Tie - 

=head1 SYNOPSIS

DWH_File::Tie is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Tie.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

