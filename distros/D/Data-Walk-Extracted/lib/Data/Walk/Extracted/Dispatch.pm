package Data::Walk::Extracted::Dispatch;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.28.0');
###InternalExtracteDDispatcH	warn "You uncovered internal logging statements for Data::Walk::Extracted::Dispatch-$VERSION" if !$ENV{hide_warn_for_test};
###InternalExtracteDDispatcH	use Data::Dumper;
use 5.010;
use utf8;
use Moose::Role;
use Carp qw( confess );

#########1 private methods    3#########4#########5#########6#########7#########8#########9

sub _dispatch_method{
    my ( $self, $dispatch_ref, $call, @arg_list ) = @_;
    ###InternalExtracteDDispatcH	warn "Made it to _dispatch_method with call: $call" if !$ENV{hide_warn_for_test};
    ###InternalExtracteDDispatcH	warn "...for dispatch ref:" . Dumper( $dispatch_ref ) if !$ENV{hide_warn_for_test};
	###InternalExtracteDDispatcH	warn "...with the passed arguments:" . Dumper( @arg_list ) if !$ENV{hide_warn_for_test};
    if( exists $dispatch_ref->{$call} ){
        my $action  = $dispatch_ref->{$call};
        ###InternalExtracteDDispatcH	warn "found the action: $call" if !$ENV{hide_warn_for_test};
        return $self->$action( @arg_list );
    }elsif( exists $dispatch_ref->{DEFAULT} ){
        my $action  = $dispatch_ref->{DEFAULT};
        ###InternalExtracteDDispatcH	warn "running the DEFAULT action ..." if !$ENV{hide_warn_for_test};
        return $self->$action( @arg_list );
    }else{
		my 	$dispatch_name =
				( exists $dispatch_ref->{name} ) ?
					$dispatch_ref->{name} : undef ;
		my	$string = "Failed to find the '$call' dispatch";
			$string .= " in the $dispatch_name" if $dispatch_name;
        confess $string;
    }
}

#########1 Phinish strong     3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Data::Walk::Extracted::Dispatch - Dispatch table management

=head1 SYNOPSIS

	package Data::Walk::Extracted;
	use Moose;
	with 'Data::Walk::Extracted::Dispatch';

	my 	$main_down_level_data ={
			###### Purpose: Used to build the generic elements of the next passed ref down
			###### Recieves: the upper ref value
			###### Returns: the lower ref value or undef
			name => '- Extracted - main down level data',
			DEFAULT => sub{ undef },
			before_method => sub{ return $_[1] },
			after_method => sub{ return $_[1] },
			branch_ref => \&_main_down_level_branch_ref,
		};


	for my $key ( keys %$upper_ref ){
		my $return = 	$self->_dispatch_method(
							$main_down_level_data, $key, $upper_ref->{$key},
						);
		$lower_ref->{$key} = $return if defined $return;
	}

	### this example will not run on it's own it just demonstrates usage!



=head1 DESCRIPTION

This role only serves the purpose of standardizing the handling of dispatch tables.  It
will first attempt to call the passed dispatch call.  If it cannot find it then it will
attempt a 'DEFAULT' call after which it will 'confess' to failure.

=head1 Methods

=head2 _dispatch_method( $dispatch_ref, $call, @arg_list ) - internal

=over

B<Definition:> To make a class extensible, the majority of the decision points
can be managed by (hash) dispatch tables.  In order to have the dispatch behavior
common across all methods this role can be attached to the class to provided for
common dispatching.  If the hash key requested is not available then the dispatch
method will attempt to call 'DEFAULT'.  If both fail the method will 'confess'.

B<Accepts:> This method expects to be called by $self.  It first receives the
dispatch table (hash) as a data reference. Next, the target hash key is accepted as
$call.  Finally, any arguments needed by the dispatch table are passed through in
@arg_list.  if the dispatch table has a name => key the value will be used in any
confessed error message.

B<Returns:> defined by the dispatch (hash) table

=back

=head1 TODO

=over

B<1.> Nothing yet!

=back

=head1 SUPPORT

=over

L<github Data-Walk-Extracted/issues|https://github.com/jandrew/Data-Walk-Extracted/issues>

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2013, 2016 by Jed Lund.

=head1 Dependencies

=over

L<version>

L<utf8>

L<Carp> - confess

L<Moose::Role>

=back

=head1 SEE ALSO

=over

L<Log::Shiras::Unhide> - Can use to unhide '###InternalExtracteDDispatcH' tags

L<Log::Shiras::TapWarn> - to manage the output of exposed '###InternalExtracteDDispatcH' lines

L<Data::Walk::Extracted>

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
