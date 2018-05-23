use Test::Script 1.10 tests => 11;

script_compiles('bin/backup-hanoi');

script_runs(['bin/backup-hanoi', 't/8_bin/example_devices.txt', 8]);
script_stdout_is("D\n", 't/8_bin/example_devices 8 -> D');

script_runs(['bin/backup-hanoi', 't/8_bin/example_devices.txt', -1]);
script_stdout_is("D\n", 't/8_bin/example_devices -1 -> D');

script_runs(['bin/backup-hanoi', 't/8_bin/example_devices.txt', -1, 1]);
script_stdout_is("D\nE\nA\n", 't/8_bin/example_devices -1 1 -> DEA');

script_runs(['bin/backup-hanoi', 't/8_bin/example_devices.txt', "init", 0]);
script_stdout_is("A\nB\nC\nD\nE\n", 't/8_bin/example_devices init 0 -> ABCDE');

script_runs(['bin/backup-hanoi', 't/8_bin/example_devices.txt', "-4", 0]);
script_stdout_is("A\nB\nC\nD\nE\n", 't/8_bin/example_devices -4 0 -> ABCDE');
