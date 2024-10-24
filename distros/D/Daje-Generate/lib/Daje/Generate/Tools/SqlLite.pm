use v5.40;
use feature 'class';
no warnings 'experimental::class';

our $VERSION = '0.01';

class Daje::Generate::Tools::SqlLite {
    use DBI;

    field $dbh :reader;
    field $data_dir :reader;
    field $path :param;

    method load_hash($file_path_name) {
        my $hash;
        try {
            my $sth = $dbh->prepare("SELECT hash FROM file_hashes WHERE file = '$file_path_name'");
            $sth->execute();
            $hash = $sth->fetch();
        } catch ($e) {
            die "Could not load hash '$e";
        };

        return $hash;
    }

    method open_database() {
        my $new = 0;
        try {
            $data_dir = $path->dirname . "/data";
            if(!( -d $data_dir)) {
                $path->make_path($data_dir);
                $new = 1;
            }
            my $dbfile = $data_dir .'/generate.db';
            $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","") or die $DBI::errstr;
        } catch ($e) {
            die "setup_database failed '$e'";
        };

        try {
            if ($new == 1) {
                my $script = $self->script();
                $dbh->do($script);
            }
        } catch ($e) {
            die "setup_database failed '$e'";
        };
    }

    method script() {
        return qq{
            CREATE TABLE IF NOT EXISTS file_hashes (
                file text PRIMARY KEY,
                hash text NOT NULL,
                moddatetime text
            );
        };
    }
}


1;
#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

lib::Daje::Generate::Tools::SqlLite - lib::Daje::Generate::Tools::SqlLite


=head1 REQUIRES

L<DBI> 

L<feature> 

L<v5.40> 


=head1 METHODS


=cut

