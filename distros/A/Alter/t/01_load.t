use Test::More;
my $n_tests;

use_ok 'Alter';
BEGIN { $n_tests += 1 }

### check imports through :all
{
    package A;
    use Alter ':all';
    main::ok defined &$_, "import $_ (:all)" for @Alter::EXPORT_OK;
    BEGIN { $n_tests += @Alter::EXPORT_OK }
}

### check individual imports
{
    package B;
    use Alter @Alter::EXPORT_OK;
    main::ok defined &$_, "import $_ (individual)" for @Alter::EXPORT_OK;
    BEGIN { $n_tests += @Alter::EXPORT_OK }
}

BEGIN { plan tests => $n_tests }
