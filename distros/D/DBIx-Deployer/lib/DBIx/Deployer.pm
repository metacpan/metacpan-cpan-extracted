use 5.14.2;
use Modern::Perl;
use Moops;


class DBIx::Deployer::Patch 1.1.1 {
    use Digest::MD5;
    use Term::ANSIColor;
    use Data::Printer colored => 1;

    has deployed => ( is => 'rw', isa => Bool, default => 0 );
    has verified => ( is => 'rw', isa => Bool, default => 0 );
    has name => ( is => 'ro', isa => Str, required => true );
    has supports_transactions => ( is => 'ro', isa => Bool, default => true );
    has dependencies => ( is => 'ro', isa => Maybe[ArrayRef] );
    has deploy_sql => ( is => 'ro', isa => Str, required => true );
    has deploy_sql_args => ( is => 'ro', isa => Maybe[ArrayRef] );
    has no_verify => ( is => 'ro', isa => Bool, default => false );
    has verify_sql => ( is => 'ro', isa => Str );
    has verify_sql_args => ( is => 'ro', isa => ArrayRef );
    has verify_expects => ( is => 'ro', isa => ArrayRef );
    has db => ( is => 'ro', isa => InstanceOf['DBI::db'], required => true );

    method deploy {
        if($self->deploy_sql_args){
          $self->db->do($self->deploy_sql, {}, @{ $self->deploy_sql_args })
            or $self->handle_error($self->db->errstr);
        }
        else{
          $self->db->do($self->deploy_sql) or $self->handle_error($self->db->errstr);
        }
    }

    before deploy {
        die colored(['red'], $self->name . " is already deployed") if $self->deployed;
        if($self->supports_transactions){ $self->db->begin_work; }
    }

    after deploy {
        $self->deployed(1);
        $self->verify;
    }

    method verify {
        if($self->no_verify){
            $self->verified(1);
            return;
        }

        unless($self->verify_sql && @{ $self->verify_expects || [] }){
            $self->handle_error($self->name . " is missing verification attributes");
        }

        my $result;

        if($self->verify_sql_args){
            $result = $self->db->selectall_arrayref($self->verify_sql, {}, @{ $self->verify_sql_args })
              or $self->handle_error($self->db->errstr);
        }
        else{
            $result = $self->db->selectall_arrayref($self->verify_sql)
              or $self->handle_error($self->db->errstr);
        }

        $self->verified($self->_check_signature($result));
    }

    after verify {
        if($self->verified){
            if($self->supports_transactions){
                $self->db->commit;
            }
            say Term::ANSIColor::colored(['green'], $self->name . " completed successfully");
        }
        else{
            $self->handle_error($self->name . " failed verification");
        }
    }

    method handle_error ( Str $error ){
        if($self->supports_transactions){
            $self->deployed(0);
            $self->db->rollback or die $self->name . ": " . $self->db->errstr;
        }
        die colored(['red'], $self->name . ": " . $error);
    }
 
    method _check_signature ( ArrayRef $result ){
        my $is_equal = $self->_signature($result) eq $self->_signature($self->verify_expects);
        unless ( $is_equal ) {
            say 'Expected:';
            say p( $self->verify_expects );
            say "\nReceived:";
            say p( $result );
        }
        return $is_equal;
    }

    multi method _signature( HashRef $params ) {
        return Digest::MD5::md5_base64(
            join(
                '',
                map {
                        $self->_signature($_)
                      . $self->_signature( $params->{$_} )
                } sort keys %$params
            )
        );
    }

    multi method _signature( ArrayRef $params ) {
        return Digest::MD5::md5_base64(
            join( '', map { $self->_signature($_) } @$params )
        );
    }

    multi method _signature( Str $params ) {
        return Digest::MD5::md5_base64($params);
    };

    multi method _signature ( Undef $params ) {
        return;
    }
}

class DBIx::Deployer 1.1.1 {
    use DBI;
    use DBD::SQLite;
    use JSON::XS;
    use Term::ANSIColor;
    use autodie;

    has target_db => ( is => 'lazy', isa => InstanceOf['DBI::db'],
        builder => method {
            die 'Missing attribute target_dsn.  Optionally, you may pass a DBI::db as target_db' unless $self->target_dsn;
            DBI->connect(
              $self->target_dsn,
              $self->target_username,
              $self->target_password
            ) or die $@;
        } 
    );

    has target_dsn => ( is => 'ro', isa => Str );
    has target_username => ( is => 'ro', isa => Str );
    has target_password => ( is => 'ro', isa => Str );

    has patch_path => ( is => 'ro', isa => Str, required => true );
    has deployer_db_file => ( is => 'ro', isa => Str );

    has deployer_db => ( is => 'lazy', isa => InstanceOf['DBI::db'],
        builder => method {
            die 'Missing attribute deployer_db_file if using SQLite for patch management' unless $self->deployer_db_file;
            my $db = DBI->connect('dbi:SQLite:dbname=' . $self->deployer_db_file) or die $@;
            my $tables = $db->selectall_arrayref('SELECT name FROM sqlite_master WHERE type = "table"') || [];

            unless(@$tables){
                $self->_init($db);
            }
            return $db;
        }
    );

    has deployer_patch_table => ( is => 'ro', isa => Str, default => 'patches' );

    has _patches_hashref => (
        is => 'rw',
        isa => HashRef,
        default => sub{ {} } 
    );
    
    has supports_transactions => ( is => 'ro', isa => Bool, default => true );
    has keep_newlines => ( is => 'ro', isa => Bool, default => false );

    method patches {
        return $self->_patches_hashref if %{ $self->_patches_hashref };

        my $patches = $self->_patches_hashref;

        opendir(my $dh, $self->patch_path);
        my @patch_files = sort readdir($dh);
        closedir($dh);

        shift @patch_files for 1..2; # Throw away "." and ".."

        foreach my $file (@patch_files){
            my $json;
            {
                local $/ = undef;
                open(my $fh, '<', $self->patch_path . '/' . $file);
                $json = <$fh>;
                close($fh);
            }
            $json=~s/\n|\r\n/ /gm unless $self->keep_newlines;            
            my $patch_array = JSON::XS::decode_json($json);
            foreach my $patch (@$patch_array) { 

                my $status = $self->deployer_db->selectrow_hashref(
                    (sprintf q|SELECT * FROM %s WHERE name = ?|, $self->deployer_patch_table),{},$patch->{name});

                $self->record_patch($patch->{name}) unless $status;

                foreach (keys %$status) {
                    $patch->{$_} = $status->{$_};
                }
                $patch->{db} = $self->target_db;
                $patch->{supports_transactions} = $self->supports_transactions;
                $patches->{ $patch->{name} } =  DBIx::Deployer::Patch->new( %$patch );
            }
        }
        $self->_patches_hashref($patches);
        return $self->_patches_hashref;
    }

    method record_patch (Str $name) {
        $self->deployer_db->do(
            (sprintf q|INSERT INTO %s (name, deployed, verified) VALUES (?, ?, ?)|, $self->deployer_patch_table),
            {}, $name, 0, 0) or die $@;
    }

    method update_patch (InstanceOf['DBIx::Deployer::Patch'] $patch) {
        $self->deployer_db->do(
            (sprintf q|UPDATE %s SET deployed = ?, verified = ? WHERE name = ?|, $self->deployer_patch_table),
            {}, map{ $patch->$_ } qw(deployed verified name)
        ) or die $@;
    }

    method deploy_all {
        my $patches = $self->patches;
        foreach my $name (keys %$patches){
            $self->deploy($patches->{$name});
        }
        return true;
    }

    method deploy (InstanceOf['DBIx::Deployer::Patch'] $patch) {
        return if $patch->deployed;

        my @dependencies = @{ $patch->dependencies || [] };

        if(@dependencies){
            my $patches = $self->patches;
            foreach my $name (@dependencies){
              if($patches->{$name}){
                $self->deploy($patches->{$name});
              }
              else{
                die colored(['red'], q|Patch "| . $patch->name . qq|" failed: Patch dependency "$name" is not defined.|);
              }
            }
        }

        eval{ $patch->deploy };
        my $error = $@;
        $self->update_patch($patch);
        if($error){ die $error; }
    }

    method _init (InstanceOf['DBI::db'] $db){
        $db->do(
            (sprintf q|CREATE TABLE %s (name VARCHAR UNIQUE, deployed INT, verified INT)|, $self->deployer_patch_table)
        ) or die $@;
    }
}

# ABSTRACT: Light-weight database patch utility
# PODNAME: DBIx::Deployer

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Deployer - Light-weight database patch utility

=head1 VERSION

version v1.1.1

=head1 SYNOPSIS

    use DBIx::Deployer;
    my $d = DBIx::Deployer->new(
      target_dsn => 'dbi:Sybase:server=foo;database=bar;',
      target_username => 'sa',
      target_password => '1234',
      patch_path => '../patches/',
      deployer_db_file => 'deployer.db',
    );

    # Run all patches (skipping over those already deployed)
    $d->deploy_all;

    # Run one patch (and its dependencies)
    my $patches = $d->patches;
    $d->deploy( $patches->{'the patch name'} );

=head1 DESCRIPTION

Stop here.  Go read about L<App::Sqitch> instead.

Still here?  That's probably because your database isn't supported by Sqitch :(. This module is a super-lightweight patch management tool that uses SQLite (see L<DBD::SQLite>) to store whether a patch has been deployed and verified.

If you're wondering why I authored this and did not contribute to Sqitch, the answer is that I needed a quick and dirty solution to hold me over until I can use Sqitch after a database migration.

=head1 VERSIONING

Semantic versioning is adopted by this module. See L<http://semver.org/>.

=head1 ATTRIBUTES

=head2 target_db (DBI::db)

This is the database handle where patches will be deployed.  You may optionally pass C<target_dsn>, C<target_username>, and C<target_password> as an alternative to C<target_db>.

=head2 target_dsn (Str)

This is the dsn for your database that you will be performing patch deployments upon.  See L<DBI> for more information on dsn strings.

=head2 target_username (Str)

The username for your database.

=head2 target_password (Str)

The password for your database.

=head2 patch_path (Str REQUIRED)

The directory path where you will store your patch files.  PLEASE NOTE: DBIx::Deployer will attempt to process *all* files in this directory as patches regardless of extension or naming convention.

=head2 deployer_db_file (Str)

This is the file path where you would like your DBIx::Deployer SQLite database to be stored. This is required if using SQLite to manage your patch information. 

=head2 deployer_db (DBI::db)

If you want your patch status information to live in a database other than SQLite, pass a DBI::db object during instantiation.  Your database storing the patches must have a table conforming to the following structure:

=over 4

=item 
* Table name: patches (you may specify a different table name by using the C<deployer_patch_table> attribute)

=item 
* Column: name VARCHAR (of acceptable length for patch names, recommended to be UNIQUE)

=item 
* Column: deployed BOOL/INT

=item 
* Column: verified BOOL/INT

=back

=head2 deployer_patch_table (Str OPTIONAL defaults to 'patches')

Set this attribute if you want patch data to be recorded in a table other than 'patches'.  See C<deployer_db>.

=head2 supports_transactions (Bool OPTIONAL defaults to true)

If your database supports transactions, C<deploy_sql> will be rolled back if verification fails, or if other errors occur during deployment of individual patches.  If your database does not support transactions, you will need to set this attribute to false.  Please be aware that without transactions, patches may find themselves in a state of being deployed but not verified... however, if that happens you'll likely have bigger fish to fry like figuring out how to repair your database. :)

=head2 keep_newlines (Bool OPTIONAL defaults to false)

For convenience and SQL readability, newlines are allowed in the SQL string values in the JSON patch files contrary to the JSON specification.  By default, these newlines will be converted to spaces before being passed to the parser.  If for some reason these transformations must not be done, set this attribute to true.

=head1 METHODS

=head2 deploy_all

This will process all patches in the C<patch_path>.  Some things to note:

=over 4

=item 
* C<deploy> is idempotent.  It will not run patch files that have already been deployed.

=item 
* If your database supports transactions, failed patches will be rolled back.  Please be aware that an entire patch file (think multiple SQL statements) will not be rolled back if a patch (think single SQL statement) within the file fails.

=back

=head2 patches

This returns an array of DBIx::Deployer::Patch objects.  This is only useful if your intent is to use these objects in conjunction with C<deploy>.

=head2 deploy (DBIx::Deployer::Patch REQUIRED)

This method deploys the patch passed as an argument AND its corresponding dependencies.

=head1 PATCH FILES

Patches are written as JSON arrays, and stored in the C<patch_path> directory.  These files must be able to be parsed by JSON::XS.

    # Patch Example
    [
      {
        "name":"insert into foo",
        "deploy_sql":"INSERT INTO foo VALUES (1, 2)",
        "verify_sql":"SELECT COUNT(*) FROM foo",
        "verify_expects":[ [1] ],
        "dependencies": [ "create table foo" ]
      },
      {
        "name":"create table foo",
        "deploy_sql":"CREATE TABLE foo(a,b)",
        "verify_sql":"PRAGMA table_info(foo)",
        "verify_expects":[ [ 0, "a", "", 0, null, 0 ], [ 1, "b", "", 0, null, 0 ] ]
      }
    ]

=head2 Patch Attributes

=head3 name (Str REQUIRED)

The name of the patch must be unique.  It will be used as the primary key for the patch, and is how you will declare it as a dependency for other patches.

=head3 dependencies (ArrayRef)

Dependencies are listed by name.  Take care not to create circular dependencies as I have no intentions of protecting against them.

=head3 deploy_sql (Str REQUIRED)

Patch files may contain multiple patches, but a single patch within a patch file may not contain more than one SQL statement to deploy.

=head3 deploy_sql_args (ArrayRef)

If using bind parameters in your C<deploy_sql> statement, the values in C<deploy_sql_args> will be used for those parameters.  See L<DBI> and L<http://www.bobby-tables.com> for more information about bind parameters.

=head3 verify_sql (Str)

This is a single query used to sanity check that your C<deploy_sql> was successful.  By default, this parameter is required.  See C<no_verify> if your use case requires deployment without verification.

=head3 verify_sql_args (ArrayRef)

If using bind parameters in your C<verify_sql> statement, the values in C<verify_sql_args> will be used for those parameters.  See L<DBI> and L<http://www.bobby-tables.com> for more information about bind parameters.

=head3 verify_expects (ArrayRef)

The C<verify_sql> is selected using C<selectall_arrayref> (see L<DBI>).  The C<verify_expects> attribute is a representation of the query result you would anticipate from the C<selectall_arrayref> method.

=head3 no_verify (Bool)

If set to true, patches will be marked verified WITHOUT having any tests run.

=head1 REPOSITORY

L<https://github.com/Camspi/DBIx-Deployer>

=head1 SEE ALSO

=over 4

=item 
* L<App::Sqitch> - seriously, use this module instead

=item 
* L<DBD::SQLite>

=item 
* L<DBI>

=back

=head1 CREDITS

=over 4

=item 
* eMortgage Logic, LLC., for allowing me to publish this module to CPAN

=back

=head1 AUTHOR

Chris Tijerina

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by eMortgage Logic LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
