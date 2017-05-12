package App::DB::Schema;
use Teng::Schema::Declare;
use App::DB::Schema::Declare;

base_row_class 'App::DB::Row';

table {
    name 'sessions';
    pk 'id';
    columns (
        {name => 'id', type => 1},
        {name => 'a_session', type => -3},
        {name => 'created_at', type => 11},
    );
};

1;
