package Bundle::Search::InvertedIndex;

$VERSION = '1.01';

1;

__END__

=head1 NAME

Bundle::Search::InvertedIndex - A bundle to install all Search::InvertedIndex related modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Search::InvertedIndex'>

=head1 CONTENTS

Digest::MD5             - For Tie::DB_File::SplitHash and Tie::FileLRUCache

Class::NamedParms       - Used by most of the system

Class::ParmList         - Used by most of the system

Tie::DB_File::SplitHash - Used by Search::InvertedIndex

Tie::FileLRUCache       - Used by Search::InvertedIndex

Search::InvertedIndex   - The Search::InvertedIndex module itself

=head1 DESCRIPTION

This bundle includes all the Search::InvertedIndex modules and modules
that it depends on.

=head1 AUTHOR

Benjamin Franz E<lt>F<snowhare@nihongo.org>E<gt>

=cut
