require "rubygems"
require "rake"
require "shipit"
require "pathname"

makefilepl = Pathname.new("Makefile.PL").read
mainmodule = Pathname.new("lib/DBIx/RewriteDSN.pm").read

NAME        = makefilepl[/name '([^']+)';/, 1]
VERS        = mainmodule[/our \$VERSION = '([^']+)';/, 1]
DESCRIPTION = mainmodule[/=head1 NAME\s+\S+ - (.*)/, 1]

task :default => :test

desc "make test"
task :test => ["Makefile"] do
	sh %{make test}
	sh %{prove -Ilib xt}
end

desc "make clean"
task :clean => ["Makefile"] do
	sh %{make clean}
end

desc "make install"
task :install => ["Makefile"] do
	sh %{sudo make install}
end

desc "release"
task :release => :shipit

desc "shipit"
task :shipit => ["MANIFEST"] do
	sh %{shipit}
end

file "Makefile" => ["Makefile.PL"] do
	sh %{perl Makefile.PL}
end

file "Makefile.PL"

file "MANIFEST" => Dir["**/*"].delete_if {|i| i == "MANIFEST" }  do
	rm "MANIFEST" if File.exist?("MANIFEST")
	sh %{perl Makefile.PL}
	sh %{make}
	sh %{make manifest}
end
