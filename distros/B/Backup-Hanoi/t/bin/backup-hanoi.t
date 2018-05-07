use Test::Script tests => 7;

script_compiles('bin/backup-hanoi');

script_runs(['bin/backup-hanoi', 't/bin/example_devices.txt', 8]);
script_stdout_is("D\n", 't/bin/example_devices 8 -> D');

script_runs(['bin/backup-hanoi', 't/bin/example_devices.txt', -1]);
script_stdout_is("D\n", 't/bin/example_devices -1 -> D');

script_runs(['bin/backup-hanoi', 't/bin/example_devices.txt', -1, 1]);
script_stdout_is("D\nE\nA\n", 't/bin/example_devices -1 1 -> DEA');
