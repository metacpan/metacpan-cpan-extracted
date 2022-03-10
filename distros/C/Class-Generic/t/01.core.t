#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test2::V0;
};

BEGIN
{
    use ok( 'Class::Generic' );
    use ok( 'Class::Array' );
    use ok( 'Class::Assoc' );
    use ok( 'Class::Boolean' );
    use ok( 'Class::DateTime' );
    use ok( 'Class::Exception' );
    use ok( 'Class::File', qw( cwd file rootdir stdin stderr stdout sys_tmpdir tempfile tempdir ) );
    use ok( 'Class::Finfo', qw( :all ) );
    use ok( 'Class::NullChain' );
    use ok( 'Class::Number' );
    use ok( 'Class::Scalar' );
};

#use strict;

subtest 'inheritance' => sub
{
    my $obj = Class::Generic->new;
    isa_ok( $obj => ['Module::Generic'] );
    my $arr = Class::Array->new;
    isa_ok( $arr => ['Module::Generic::Array'] );
    my $bool = Class::Boolean->new;
    isa_ok( $bool => ['Module::Generic::Boolean'] );
    my $dt = Class::DateTime->new;
    isa_ok( $dt => ['Module::Generic::DateTime'] );
    my $ex = Class::Exception->new;
    isa_ok( $ex => ['Module::Generic::Exception'] );
    my $file = Class::File->new( 'test.txt' );
    isa_ok( $file => ['Module::Generic::File'] );
    is( $file->basename, 'test.txt' );
    my $finfo = Class::Finfo->new( __FILE__ );
    isa_ok( $finfo, ['Module::Generic::Finfo'] );
    my $hash = Class::Assoc->new;
    isa_ok( $hash, ['Module::Generic::Hash'] );
    my $null = Class::NullChain->new;
    isa_ok( $null, ['Module::Generic::Null'] );
    my $num = Class::Number->new(10);
    isa_ok( $num, ['Module::Generic::Number'] );
    my $str = Class::Scalar->new( 'test' );
    isa_ok( $str, ['Module::Generic::Scalar'] );
    
    foreach my $sub ( qw( cwd file rootdir stdin stderr stdout sys_tmpdir tempfile tempdir ) )
    {
        can_ok( $file, $sub );
        ok( defined( &$sub ), "sub $sub is exported" );
    }
};

subtest 'constants' => sub
{
    my $constants = [
        #  the file type is undetermined.
        FILETYPE_NOFILE => 0,
        # a file is a regular file.
        FILETYPE_REG => 1,
        # a file is a directory
        FILETYPE_DIR => 2,
        # a file is a character device
        FILETYPE_CHR => 3,
        # a file is a block device
        FILETYPE_BLK => 4,
        # a file is a FIFO or a pipe.
        FILETYPE_PIPE => 5,
        # a file is a symbolic link
        FILETYPE_LNK => 6,
        # a file is a [unix domain] socket.
        FILETYPE_SOCK => 7,
        # a file is of some other unknown type or the type cannot be determined.
        FILETYPE_UNKFILE => 127,
    ];

    for( my $i = 0; $i < scalar( @$constants ); $i += 2 )
    {
        my $const = $constants->[$i];
        my $value = $constants->[$i + 1];
        ok( defined( &$const ), "constant $const defined" );
        if( defined( &$const ) )
        {
            is( &$const, $value, "constant $const value" );
        }
        else
        {
            fail( "constant $const value" );
        }
    }
};

done_testing();

__END__

