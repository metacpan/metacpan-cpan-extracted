#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

ok $dbh->do('CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR)') == 0, 'Create sudents table';

ok $dbh->do('CREATE TABLE subjects (id INTEGER PRIMARY KEY, name VARCHAR)') == 0, 'Create subjects table';

ok $dbh->do(
    'CREATE TABLE exams (
    exam_id INTEGER PRIMARY KEY,
    subject_id INTEGER REFERENCES subjects(id),
    student_id INTEGER REFERENCES students(id),
    grade INTEGER
)'
) == 0, 'Create exams table';


ok $dbh->do(q{INSERT INTO students VALUES (1, 'Student 1')}) == 1, 'Insert student';
ok $dbh->do(q{INSERT INTO subjects VALUES (1, 'CS 101')}) == 1,    'Insert subject';
ok $dbh->do(q{INSERT INTO exams VALUES (1, 1, 1, 10)}) == 1,       'Insert exam';
ok !$dbh->do(q{INSERT INTO exams VALUES (2, 1, 2, 10)}),           'Insert exam (constraint error)';

my $fk = $dbh->foreign_key_info(undef, undef, undef, undef, undef, undef)->fetchall_hashref('FK_COLUMN_NAME');

ok $fk->{student_id}, 'FK student_id';
ok $fk->{subject_id}, 'FK subject_id';

done_testing;
