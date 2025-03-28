package Daje::Workflow::FileChanged::Database::DB;
use Mojo::Base -base, -signatures;


our $VERSION = "0.01";

__DATA__

@@ file_changed
-- 1 up
CREATE TABLE IF NOT EXISTS file_hashes (
    file text PRIMARY KEY,
    hash text NOT NULL,
    moddatetime timestamp not null default now()
);

-- 1 down
DROP TABLE file_hashes;

__END__

1;

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Daje::Workflow::FileChanged::Database::DB


=head1 DESCRIPTION

pod generated by Pod::Autopod - keep this line to make pod updates possible ####################


=head1 REQUIRES

L<Mojo::Base> 


=head1 METHODS


=cut

