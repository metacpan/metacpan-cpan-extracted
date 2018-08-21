package CSV::Processor::Utils;
$CSV::Processor::Utils::VERSION = '1.01';


use File::Basename;
use File::Spec;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  insert_after_index
  make_prefix
);
our %EXPORT_TAGS = ( 'ALL' => [@EXPORT_OK] );


sub make_prefix {
    my ( $path, $prefix ) = @_;
    my ( $name, $path, $suffix ) = fileparse( $path, qw/csv CSV/ );
    my $new_name = $prefix . '' . $name . '' . $suffix;
    File::Spec->catfile( $path, $new_name );
}

# sub insert_after_index ($$\@)
sub insert_after_index {
    my ( $index, $val_to_insert, $list ) = @_;
    return 0 if $#$list < $index;
    my @part1 = splice @$list, $index + 1;
    my @part2 = splice @$list;
    @$list = ( @part2, $val_to_insert, @part1 );
    return 1;
}

sub leave_only_digits {
    my $number = shift;
    $number =~ s/\D//g;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CSV::Processor::Utils

=head1 VERSION

version 1.01

=head1 SYNOPSIS

  use CSV::Processor::Utils qw( insert_after_index )
  # or CSV::Processor::Utils qw[:ALL];
  
  my $text = insert_after_index($index, $val_to_insert, $list)

=head2 insert_after_index

Insert element after particular index

Someone please add this function to L<List::MoreUtils>

    insert_after_index($index, $val_to_insert, $list)

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
