Name:           BuzzSaw
Summary:        Tools for parsing and filtering log files
Version:        0.12.0
Release:        1
Packager:       Stephen Quinney <squinney@inf.ed.ac.uk>
License:        GPLv2
Group:          LCFG/Utilities
Source:         BuzzSaw-0.12.0.tar.gz
BuildArch:	noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildRequires:  perl >= 1:5.6.1
BuildRequires:  perl(Module::Build), perl(Test::More) >= 0.87
BuildRequires:  perl(DBIx::Class), perl(DBD::Pg)
BuildRequires:  perl(DateTime), perl(DateTime::Format::Pg)
BuildRequires:  perl(IO::Uncompress::Bunzip2), perl(IO::Uncompress::Gunzip)
BuildRequires:  perl(Digest::SHA)
BuildRequires:  perl(File::Find::Rule)
BuildRequires:  perl(Moose)
BuildRequires:  perl(MooseX::Types), perl(MooseX::Log::Log4perl)
BuildRequires:  perl(MooseX::SimpleConfig), perl(MooseX::App::Cmd)
BuildRequires:  perl(MooseX::Types::EmailAddress)
BuildRequires:  perl(Readonly)
BuildRequires:  perl(UNIVERSAL::require)
BuildRequires:  perl(YAML::Syck), perl(Text::Diff)
BuildRequires:  perl(Template)

# These are Moose roles so don't get automatically identified.
Requires:       perl(MooseX::Log::Log4perl), perl(MooseX::SimpleConfig)
Requires:       perl(MooseX::Getopt), perl(MooseX::App::Cmd)
# DBIx::Class loads these dynamically
Requires:       perl(DBIx::Class)
Requires:       perl(DBD::Pg), perl(DateTime::Format::Pg)

%description
Tools for parsing and filtering log files

%prep
%setup -q -n BuzzSaw-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

mkdir -p $RPM_BUILD_ROOT/var/lib/buzzsaw

mkdir -p $RPM_BUILD_ROOT/usr/share/buzzsaw/data
cp nonpersonal.txt $RPM_BUILD_ROOT/usr/share/buzzsaw/data

%check
./Build test

%files
%defattr(-,root,root)
%doc ChangeLog
%doc %{_mandir}/man1/*
%doc %{_mandir}/man3/*
%{perl_vendorlib}/BuzzSaw
%{perl_vendorlib}/App/*
%{_bindir}/*
/usr/share/buzzsaw/
%attr(0770,logfiles,logfiles)/var/lib/buzzsaw

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Fri Apr 05 2013 SVN: new release
- Release: 0.12.0

* Fri Apr 05 2013 12:36 squinney@INF.ED.AC.UK
- buzzsaw.sql: throw more indexes at the event table in a bid to
  make reports quicker

* Fri Apr 05 2013 12:33 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Report.pm.in,
  lib/BuzzSaw/Report/Kernel.pm.in, lib/BuzzSaw/Report/Sleep.pm.in:
  Added support for restricting report queries by the value of the
  program field. This helps speed things up when the query might
  return a lot of results. Also altered the default for the tags
  list. This is now empty by default which makes a bit more sense
  in most cases where the program field is set to the name of the
  report. Reports should define the list of tags they want

* Thu Apr 04 2013 16:08 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.11.3

* Thu Apr 04 2013 16:08 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/DB/Schema/Result/Event.pm.in,
  lib/BuzzSaw/Report.pm.in, templates/reports/sleep.tt: Completely
  reworked how we get the localtime for an event. This will
  hopefully be a lot faster and has the added bonus of providing a
  more generally useful method

* Thu Apr 04 2013 06:42 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.11.2

* Thu Apr 04 2013 06:42 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Cosign.pm.in, lib/BuzzSaw/Filter/Kernel.pm.in,
  lib/BuzzSaw/Filter/SSH.pm.in, lib/BuzzSaw/Filter/Sleep.pm.in,
  lib/BuzzSaw/Filter/UserClassifier.pm.in: More variable name fixes

* Thu Apr 04 2013 06:39 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.11.1

* Thu Apr 04 2013 06:36 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Fixed variable name

* Wed Apr 03 2013 19:40 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.11.0

* Wed Apr 03 2013 19:38 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in, lib/BuzzSaw/Types.pm.in: Added support
  in reports for moving the event timestamps from UTC into another
  timezone

* Fri Mar 29 2013 11:30 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.10.4

* Fri Mar 29 2013 11:29 squinney@INF.ED.AC.UK
- docs/filters.html: list the named constants for the filter voting
  system

* Fri Mar 29 2013 11:28 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter.pm.in, lib/BuzzSaw/Filter/Cosign.pm.in,
  lib/BuzzSaw/Filter/Kernel.pm.in, lib/BuzzSaw/Filter/SSH.pm.in,
  lib/BuzzSaw/Filter/Sleep.pm.in,
  lib/BuzzSaw/Filter/UserClassifier.pm.in,
  lib/BuzzSaw/Importer.pm.in: Reworked the voting system so that it
  uses named constants. This improves the clarity of the decision
  making

* Fri Mar 29 2013 10:58 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Added bulk precedence heder in the
  email sending code to avoid vacation auto-responses

* Fri Mar 29 2013 10:38 squinney@INF.ED.AC.UK
- docs/database.html, lib/BuzzSaw/DB.pm.in: more database docs

* Fri Mar 29 2013 10:03 squinney@INF.ED.AC.UK
- docs/database.html: Added basic details of the database schema

* Thu Mar 28 2013 18:11 squinney@INF.ED.AC.UK
- docs/design.html: fixed closing tag

* Thu Mar 28 2013 17:00 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.10.3

* Thu Mar 28 2013 16:59 squinney@INF.ED.AC.UK
- MANIFEST: Updated list of files in manifest

* Thu Mar 28 2013 16:58 squinney@INF.ED.AC.UK
- META.yml.in, Makefile.PL, lcfg.yml: updated meta files for cpan

* Thu Mar 28 2013 16:48 squinney@INF.ED.AC.UK
- Build.PL.in, META.yml.in: Added missing deps

* Thu Mar 28 2013 15:26 squinney@INF.ED.AC.UK
- docs/filters.html, docs/reports.html: reports docs

* Thu Mar 28 2013 14:15 squinney@INF.ED.AC.UK
- docs/filters.html: updated to reflect reality

* Thu Mar 28 2013 12:51 squinney@INF.ED.AC.UK
- docs/intro.html, lib/BuzzSaw/Parser/RFC3339.pm.in: small tweaks
  to docs

* Thu Mar 28 2013 12:51 squinney@INF.ED.AC.UK
- docs/design.html: Added more high-level design docs

* Thu Mar 28 2013 11:05 squinney@INF.ED.AC.UK
- docs/intro.html: First pass on intro docs

* Fri Mar 15 2013 14:22 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.10.2

* Fri Mar 15 2013 14:22 squinney@INF.ED.AC.UK
- lcfg.yml, templates/reports/sleep.tt: Avoid blank lines

* Fri Mar 15 2013 14:09 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.10.1

* Fri Mar 15 2013 14:09 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Report.pm.in,
  lib/BuzzSaw/Report/Kernel.pm.in, lib/BuzzSaw/Report/Sleep.pm.in:
  Reworked how the default value for the report module tags list is
  handled. Now it defaults to containing the lower-cased version of
  the name attribute. This avoids the possibility of the module
  being given ALL events for the period to be processed when no
  specific tag list has been set

* Fri Mar 15 2013 09:57 cc@INF.ED.AC.UK
- ChangeLog, lib/BuzzSaw/Report/Sleep.pm.in: add default sleep tag
  to sleep report module

* Thu Mar 14 2013 16:16 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.10.0

* Thu Mar 14 2013 16:16 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/UserClassifier.pm.in: Added docs

* Thu Mar 14 2013 15:18 squinney@INF.ED.AC.UK
- lib/BuzzSaw/UserClassifier.pm.in: Set svn:keywords

* Thu Mar 14 2013 15:17 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/UserClassifier.pm.in: Switched
  BuzzSaw::UserClassifier to be an attribute, this means we can
  lazily build it when required rather than at module load time.
  Also added documentation for the module

* Thu Mar 14 2013 15:16 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Cosign.pm.in, lib/BuzzSaw/Filter/SSH.pm.in,
  lib/BuzzSaw/Filter/Sleep.pm.in: updated docs

* Thu Mar 14 2013 15:15 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/Sleep.pm.in: Set svn:keywords

* Thu Mar 14 2013 15:15 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter.pm.in: Updated docs

* Thu Mar 14 2013 15:13 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Updated docs

* Thu Mar 14 2013 15:11 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Altered the voting process slightly.
  Now anything returning a true value will have the tags retained
  but the entry (and tags) will only be stored if one or more
  filter returns a positive value. This change helps
  post-processing where we need tags to be retained but do not want
  to alter the current state of the votes

* Thu Mar 14 2013 14:15 squinney@INF.ED.AC.UK
- t/00_use.t: Test new modules

* Thu Mar 14 2013 14:09 squinney@INF.ED.AC.UK
- BuzzSaw.spec, lcfg.yml, nonpersonal.txt: Added current list of
  usernames which are considered to be non-personal

* Thu Mar 14 2013 14:08 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Kernel.pm.in, lib/BuzzSaw/Filter/Sleep.pm.in:
  unimport moose once it is not required

* Thu Mar 14 2013 14:08 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Made it much simpler to add new
  directories to the template search path. Made it possible to
  alter the default sort order

* Thu Mar 14 2013 14:07 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter.pm.in: Added a basic name attribute

* Thu Mar 14 2013 14:07 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Tweaked slightly so that when calling
  a filter the current number of votes and the results of the
  previous filters are passed in. This makes it much easier to do
  post-processing (such as user classification)

* Thu Mar 14 2013 14:06 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/UserClassifier.pm.in,
  lib/BuzzSaw/UserClassifier.pm.in: Added new module for
  classifying type of user name (root, nonperson, real, others)

* Tue Mar 12 2013 15:28 cc@INF.ED.AC.UK
- ChangeLog, MANIFEST, META.yml.in, lcfg.yml: added a sleep report
  module

* Tue Mar 12 2013 15:24 cc@INF.ED.AC.UK
- lib/BuzzSaw/Report/Sleep.pm.in: Sleep report

* Tue Mar 12 2013 14:21 cc@INF.ED.AC.UK
- templates/reports/sleep.tt: simple sleep report

* Fri Feb 01 2013 11:42 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.9.4

* Fri Feb 01 2013 11:41 squinney@INF.ED.AC.UK
- BuzzSaw.spec: Added missing build-requirements on perl(Template)

* Fri Feb 01 2013 11:32 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.9.3

* Fri Feb 01 2013 11:32 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.9.2

* Fri Feb 01 2013 11:30 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd/AnonymiseData.pm.in: minor tweak to debugging

* Fri Feb 01 2013 11:24 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.9.1

* Fri Feb 01 2013 11:23 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd/AnonymiseData.pm.in: Fixed default value for db
  config file

* Fri Feb 01 2013 11:18 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.9.0

* Fri Feb 01 2013 11:18 squinney@INF.ED.AC.UK
- buzzsaw.sql, lcfg.yml, lib/BuzzSaw/Cmd/AnonymiseData.pm.in: Added
  command for anonymising old data

* Fri Feb 01 2013 11:17 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: corrected a bug with the way the
  new_with_config method was called for BuzzSaw::DB

* Wed Jan 30 2013 20:38 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB/Schema/Result/Event.pm.in: Added support for new
  logdate column

* Fri Jan 25 2013 12:02 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.8.3

* Fri Jan 25 2013 12:02 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/DataSource/Files.pm.in: Added support for
  controlling the order in which files are parsed. Added the
  ability to set a size limit so we do not attempt to parse
  enormous files

* Mon Jan 14 2013 14:21 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.8.2

* Mon Jan 14 2013 14:21 squinney@INF.ED.AC.UK
- t/00_use.t: bumped number of tests

* Mon Jan 14 2013 14:12 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.8.1

* Mon Jan 14 2013 14:11 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Cosign.pm.in, t/00_use.t: Fixed typo. Added
  tests for new filter modules so we will spot this quicker next
  time

* Mon Jan 14 2013 14:01 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.8.0

* Mon Jan 14 2013 14:01 squinney@INF.ED.AC.UK
- buzzsaw.sql: Added an index on the name column of the extra_info
  table

* Mon Jan 14 2013 13:57 squinney@INF.ED.AC.UK
- buzzsaw.sql, lcfg.yml, lib/BuzzSaw/Filter/SSH.pm.in: Now stores
  the authentication method in the extra_info table

* Mon Dec 17 2012 17:28 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Cosign.pm.in: slightly tweaked the extra
  information which is stored

* Mon Dec 17 2012 17:19 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Cosign.pm.in: Added filter for cosign login
  events

* Mon Dec 17 2012 16:28 cc@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Sleep.pm.in: first version of a Sleep filter

* Mon Nov 26 2012 14:13 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.7

* Mon Nov 26 2012 14:13 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in, lib/BuzzSaw/Report/AuthFailure.pm.in: Fixed
  bug with counting the rows after having called finish()

* Thu Nov 22 2012 14:51 squinney@INF.ED.AC.UK
- docs/filters.html: Added docs on writing filters

* Wed Nov 21 2012 12:52 squinney@INF.ED.AC.UK
- docs, docs/filters.html, lib/BuzzSaw/Filter/SSH.pm.in: Started
  docs on how to write filters

* Fri Oct 05 2012 14:40 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/AuthFailure.pm.in,
  templates/reports/auth_failure.tt: Added target and source host
  lists to report

* Fri Oct 05 2012 14:30 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/AuthFailure.pm.in: fixed sort order

* Fri Oct 05 2012 14:27 squinney@INF.ED.AC.UK
- BuzzSaw.spec, lib/BuzzSaw/Report/AuthFailure.pm.in,
  templates/reports/auth_failure.tt: Working on auth failures
  report

* Fri Oct 05 2012 09:55 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.6

* Fri Oct 05 2012 09:55 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/DB.pm.in: Truncate some varchar event
  fields if the contents is too long, this avoids the DB throwing
  an error when we try to do an insert

* Fri Sep 14 2012 14:11 squinney@INF.ED.AC.UK
- templates/reports/auth_failure.tt: Corrected the retrieval of the
  processed data

* Fri Sep 14 2012 14:11 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/AuthFailure.pm.in: hashref not has for search

* Fri Sep 14 2012 14:03 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/AuthFailure.pm.in: Added missing semi-colon

* Fri Sep 14 2012 13:57 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/AuthFailure.pm.in, t/00_use.t,
  templates/reports/auth_failure.tt: Added new report for
  authentication failures

* Fri Sep 14 2012 10:49 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.5

* Fri Sep 14 2012 10:49 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Fixed the register_log method

* Thu Sep 13 2012 16:25 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.4

* Thu Sep 13 2012 16:24 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/SSH.pm.in: Fixed the program name check,
  should be 'sshd' not 'ssh'

* Thu Sep 13 2012 16:03 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.3

* Thu Sep 13 2012 15:44 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.2

* Thu Sep 13 2012 15:44 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Reworked register_log slightly so we can
  properly handle the situation where we are deliberately
  re-reading logfiles

* Thu Sep 13 2012 15:20 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.1

* Thu Sep 13 2012 15:20 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/DB/Schema/Result/ExtraInfo.pm.in,
  lib/BuzzSaw/Filter/SSH.pm.in, t/00_use.t: Fixed a couple of minor
  typos

* Thu Sep 13 2012 15:13 squinney@INF.ED.AC.UK
- t/00_use.t: Added basic test for new filter

* Thu Sep 13 2012 15:12 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.7.0

* Thu Sep 13 2012 15:12 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB/Schema/Result/ExtraInfo.pm.in,
  lib/BuzzSaw/Filter/SSH.pm.in: Added new filter for finding events
  associated with SSH logins

* Thu Sep 13 2012 15:07 squinney@INF.ED.AC.UK
- buzzsaw.sql, lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Event.pm.in,
  lib/BuzzSaw/DB/Schema/Result/ExtraInfo.pm.in: Added support for
  storing arbitrary key/value pairs as extra information associated
  with an event

* Thu Aug 23 2012 15:07 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/Kernel.pm.in, lib/BuzzSaw/ReportLog.pm.in:
  Added docs

* Thu Aug 23 2012 13:40 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/Kernel.pm.in: Added docs

* Thu Aug 23 2012 13:25 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Added docs

* Thu Aug 23 2012 07:47 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.6.5

* Thu Aug 23 2012 07:47 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd/Report.pm.in, lib/BuzzSaw/Reporter.pm.in: Renamed
  the report command 'force' option to 'all' which makes the
  intended purpose clearer

* Wed Aug 22 2012 14:34 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.6.4

* Wed Aug 22 2012 14:34 squinney@INF.ED.AC.UK
- Build.PL.in, BuzzSaw.spec, META.yml.in, Makefile.PL: added
  missing dependency

* Wed Aug 22 2012 14:33 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.6.3

* Wed Aug 22 2012 14:32 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Report.pm.in: Switched to using
  MooseX::Types::EmailAddress types for the To and Cc fields when
  sending reports by email

* Wed Aug 15 2012 17:44 squinney@INF.ED.AC.UK
- buzzsaw.sql: Granted permission to the logfiles_writer user to
  delete entries in current_processing table

* Wed Aug 15 2012 17:41 squinney@INF.ED.AC.UK
- buzzsaw.sql: Added commands to grant access permissions

* Wed Aug 15 2012 17:40 squinney@INF.ED.AC.UK
- buzzsaw-dbinit.sh: Added basic database setup script

* Wed Aug 15 2012 15:12 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.6.2

* Wed Aug 15 2012 15:12 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/DataSource/Files.pm.in,
  lib/BuzzSaw/Types.pm.in: Reworked file names attribute type to
  allow scalar string or regexp values to be coerced into a
  single-element list

* Wed Aug 15 2012 11:59 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.6.1

* Wed Aug 15 2012 11:59 squinney@INF.ED.AC.UK
- BuzzSaw.spec: Added missing build-dep

* Wed Aug 15 2012 11:42 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.6.0

* Wed Aug 15 2012 11:42 squinney@INF.ED.AC.UK
- BuzzSaw.spec, lcfg.yml, lib/BuzzSaw/Cmd/Report.pm.in,
  lib/BuzzSaw/Report.pm.in, lib/BuzzSaw/ReportLog.pm.in,
  lib/BuzzSaw/Reporter.pm.in, lib/BuzzSaw/Types.pm.in, t/00_use.t:
  Completed support for running reports from the command line

* Tue Aug 14 2012 10:43 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.5.5

* Tue Aug 14 2012 10:41 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Use the new BuzzSawDateTime type.
  Tidied various bits of the Moose code

* Tue Aug 14 2012 10:37 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DateTime.pm.in: Added documentation

* Tue Aug 14 2012 10:37 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: Added support for the BuzzSawDateTime
  class

* Tue Aug 14 2012 10:36 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Ensure the BuzzSaw::DB module is
  always loaded

* Wed Jul 18 2012 09:22 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.5.4

* Wed Jul 18 2012 09:22 squinney@INF.ED.AC.UK
- BuzzSaw.spec: Added even more build dependencies

* Wed Jul 18 2012 09:15 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.5.3

* Wed Jul 18 2012 09:15 squinney@INF.ED.AC.UK
- BuzzSaw.spec: Added various missing dependencies and
  build-dependencies

* Wed Jul 18 2012 08:53 squinney@INF.ED.AC.UK
- MANIFEST: Updated the MANIFEST

* Wed Jul 18 2012 08:51 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.5.2

* Wed Jul 18 2012 08:42 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd.pm.in, lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DataSource.pm.in, lib/BuzzSaw/DataSource/Files.pm.in,
  lib/BuzzSaw/Importer.pm.in, lib/BuzzSaw/Parser/RFC3339.pm.in:
  Various small tweaks to make perlcritic happier

* Tue Jul 17 2012 14:00 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: reduced excessive debugging

* Tue Jul 17 2012 13:47 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd.pm.in: Set the levels on the root-level logger

* Tue Jul 17 2012 13:36 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd.pm.in: Added support for controlling the logging
  from the applications

* Tue Jul 17 2012 12:50 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.5.1

* Tue Jul 17 2012 12:50 squinney@INF.ED.AC.UK
- BuzzSaw.spec: Include new man1 man pages

* Tue Jul 17 2012 12:49 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.5.0

* Tue Jul 17 2012 12:29 squinney@INF.ED.AC.UK
- bin/buzzsaw.in: Added usage documentation

* Tue Jul 17 2012 11:18 squinney@INF.ED.AC.UK
- lib/App/BuzzSaw.pm.in, lib/BuzzSaw/Cmd.pm.in,
  lib/BuzzSaw/Cmd/Import.pm.in, lib/BuzzSaw/Importer.pm.in: Added
  more complete documentation

* Mon Jul 16 2012 15:54 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Cmd/Import.pm.in, t/00_use.t: Updated to
  work with configuring the Importer via a file. Added a couple of
  useful command line options. Added a basic compilation test

* Mon Jul 16 2012 15:26 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd.pm.in: fixed package name

* Mon Jul 16 2012 14:43 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Allowed the parsing to fail, just log
  the error. Added full documentation

* Mon Jul 16 2012 13:49 squinney@INF.ED.AC.UK
- Build.PL.in, META.yml.in, Makefile.PL, lcfg.yml: Removed
  requirement for List::MoreUtils which is not actually being used

* Mon Jul 16 2012 13:48 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Switched to using logger
  methods. Added full documentation for module. Did a bit of code
  tidying

* Mon Jul 16 2012 13:48 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Used new checksum_data method to
  compute digest

* Mon Jul 16 2012 13:47 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource.pm.in: Added new checksum methods to
  return SHA-256 digests for files and data. Added full
  documentation for the module

* Mon Jul 16 2012 13:46 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Parser.pm.in: Small docs tweak

* Thu Jul 12 2012 15:28 squinney@INF.ED.AC.UK
- t/00_use.t: Removed test for Auth filter which was deleted

* Thu Jul 12 2012 15:24 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Switched to using the new
  BuzzSawDataSourceList type. Tidied the code a bit more

* Thu Jul 12 2012 15:24 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource.pm.in, lib/BuzzSaw/DataSource/Files.pm.in:
  Added support for loading attributes from a configuration files

* Thu Jul 12 2012 14:46 squinney@INF.ED.AC.UK
- BuzzSaw.spec: added new files to specfile

* Thu Jul 12 2012 14:45 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: Need to include the ArrayRef moose type

* Thu Jul 12 2012 14:43 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: added missing commas

* Thu Jul 12 2012 14:42 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: added missing commas

* Thu Jul 12 2012 14:41 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: added missing semi-colon

* Thu Jul 12 2012 14:40 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Types.pm.in: Add DataSource type and various
  coercions. Also added DataSource List type which should make it
  possible to load objects using info stored in yaml config files

* Wed Jul 11 2012 16:37 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in, lib/BuzzSaw/Types.pm.in: Converted
  the list of filters to the new BuzzSawFilterList type so that we
  can easily load them by name

* Wed Jul 11 2012 15:04 squinney@INF.ED.AC.UK
- lib/App/BuzzSaw.pm.in, lib/BuzzSaw/Catalogue,
  lib/BuzzSaw/Catalogue.pm.in, lib/BuzzSaw/Cmd.pm.in,
  lib/BuzzSaw/DateTime.pm.in, lib/BuzzSaw/Report/Kernel.pm.in,
  lib/BuzzSaw/Reporter.pm.in: Removed usage of Catalogue role

* Wed Jul 11 2012 15:04 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Removed usage of Catalogue role

* Wed Jul 11 2012 15:03 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Cmd/Import.pm.in, lib/BuzzSaw/DataSource.pm.in,
  lib/BuzzSaw/DataSource/Files.pm.in, lib/BuzzSaw/Importer.pm.in,
  lib/BuzzSaw/Report.pm.in, lib/BuzzSaw/Types.pm.in: Using the new
  types system for the BuzzSaw::DB object, this makes it easier to
  load a new object using a config file name. Also eradicated the
  Catalogue role, it's increasingly pointless as everything is tied
  to the database interface

* Wed Jul 11 2012 14:01 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Removed incorrect section of documentation

* Wed Jul 11 2012 14:01 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter.pm.in, lib/BuzzSaw/Filter/Auth.pm.in,
  lib/BuzzSaw/Filter/Kernel.pm.in, lib/BuzzSaw/Parser.pm.in,
  lib/BuzzSaw/Parser/RFC3339.pm.in: Added documentation

* Wed Jul 11 2012 11:17 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in, lib/BuzzSaw/DB/Schema.pm.in,
  lib/BuzzSaw/DB/Schema/Result/CurrentProcessing.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Event.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Log.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Tag.pm.in: Added documentation for
  all the modules related to the database. Added some support for
  printing out useful debugging info from the various method in
  BuzzSaw::DB

* Mon Jul 09 2012 20:03 squinney@INF.ED.AC.UK
- bin, bin/buzzsaw.in, lib/App, lib/App/BuzzSaw.pm.in,
  lib/BuzzSaw/Cmd, lib/BuzzSaw/Cmd.pm.in,
  lib/BuzzSaw/Cmd/Import.pm.in: First pass on adding a commandline
  client for various utilities

* Mon Jul 09 2012 16:26 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Importer.pm.in: Store timestamps for events in UTC

* Mon Jul 09 2012 13:21 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.4.0

* Mon Jul 09 2012 13:21 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Reporter.pm.in, t/00_use.t: Added module to
  run sets of reports each hour/day/week/month

* Mon Jul 09 2012 13:21 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Added basic support for sending reports
  via email

* Mon Jul 09 2012 13:20 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DateTime.pm.in: Added support for seconds since unix
  epoch. Reworked general string parsing to use
  Date::Parse::strptime which allows us to preserve any timezone

* Mon Jul 09 2012 08:58 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.3.0

* Mon Jul 09 2012 08:58 squinney@INF.ED.AC.UK
- Build.PL.in, BuzzSaw.spec, lcfg.yml: Added support for installing
  the templates into the package

* Mon Jul 09 2012 08:58 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in, lib/BuzzSaw/Report/Kernel.pm.in,
  templates, templates/reports, templates/reports/kernel.tt:
  Completed the basics of the report generating framework. The
  kernel events report now works.

* Fri Jul 06 2012 15:38 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DateTime.pm.in: fixed timezone handling

* Fri Jul 06 2012 15:08 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Do not prefetch tags for each event as
  it messes things up at a later stage

* Fri Jul 06 2012 14:49 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report/Kernel.pm.in: process the events into separate
  sets based on the tag names

* Fri Jul 06 2012 14:28 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Need to load the BuzzSaw::DB module

* Fri Jul 06 2012 14:23 squinney@INF.ED.AC.UK
- t/00_use.t: Now 10 tests

* Fri Jul 06 2012 14:22 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in: Need to use references to vars hash

* Fri Jul 06 2012 14:21 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in, t/00_use.t: Fixed typo, added basic
  compilation tests for new modules

* Fri Jul 06 2012 14:19 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Report.pm.in, lib/BuzzSaw/Report/Kernel.pm.in:
  Further work on the report generation process

* Fri Jul 06 2012 12:05 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Report, lib/BuzzSaw/Report.pm.in,
  lib/BuzzSaw/Report/Kernel.pm.in: Made a start on a report
  generator framework

* Fri Jul 06 2012 12:05 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DateTime.pm.in: Added new module to handle dates.
  This is a sub-class of the DateTime module with one extra method,
  named from_date_string, which can parse various extra date
  strings which are supported by the Linux audit framework

* Fri Jul 06 2012 12:04 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Added support for setting attributes from a
  configuration file using MooseX::SimpleConfig

* Wed Jul 04 2012 15:40 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Removed debug code to make
  things quieter

* Wed Jul 04 2012 15:37 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Removed debug code to make things quieter

* Wed Jul 04 2012 15:25 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Added missing schema variable

* Wed Jul 04 2012 15:24 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Reworked check_log_seen to work directly
  with the DBI layer. This should make things quicker

* Wed Jul 04 2012 15:18 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Parser/RFC3339.pm.in: Completely reworked
  the parser. This should be correct more of the time and it's
  better at guessing the name/pid for programs. It should also be
  slightly faster as the regular expressions are no longer
  recompiled on every call to the subroutine.

* Mon Jul 02 2012 16:32 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Adjusted some debugging so it is clearer
  why a file is not going to be processed

* Mon Jul 02 2012 16:25 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DataSource/Files.pm.in: Fixed scoping issue in the
  _next_filename method

* Mon Jul 02 2012 16:14 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: changed order in BUILD to
  avoid files list being unnecessarily calculated twice

* Mon Jul 02 2012 16:04 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Reworked the way the next
  filename in the list is selected so that more work is done in a
  single query in the DB. This is cleaner and should be more
  efficient

* Mon Jul 02 2012 16:01 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: reworked the start_processing method to use
  the new version of the register_current_processing DB function

* Mon Jul 02 2012 15:58 squinney@INF.ED.AC.UK
- buzzsaw.sql: altered the register_current_processing function so
  that it also does the checking of the previously seen logs table,
  this should be safer and more efficient

* Mon Jul 02 2012 15:10 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Randomised the order of the
  files found to try and make things slightly more efficient

* Mon Jul 02 2012 14:48 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Allow perl regexps to be used
  for matching the file names

* Mon Jul 02 2012 10:20 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.2.1

* Mon Jul 02 2012 10:20 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Parser/RFC3339.pm.in: Handle an empty message string

* Mon Jul 02 2012 10:15 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Auth.pm.in, t, t/00_use.t: Added basic
  compilation tests

* Mon Jul 02 2012 09:55 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Filter/Auth.pm.in, lib/BuzzSaw/Filter/Kernel.pm.in:
  Added 'o' flag to some regular expressions to hopefully make them
  a little bit faster

* Mon Jul 02 2012 09:15 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.2.0

* Mon Jul 02 2012 09:07 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Reworked slightly how we
  check if the next filename is already being processed

* Sun Jul 01 2012 20:57 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: First attempt at marking the
  beginning and end of processing

* Fri Jun 29 2012 16:20 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in: Fixed function name

* Fri Jun 29 2012 16:17 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DB/Schema/Result/CurrentProcessing.pm.in: Added
  support for registering that processing of a file has
  started/ended. This will help multiple processors avoid parsing
  the same files at the same time

* Fri Jun 29 2012 15:52 squinney@INF.ED.AC.UK
- buzzsaw.sql: Added new table for tracking the file currently
  being processed. Also added a function which will query this
  table with locking and timeout support

* Thu Jun 28 2012 15:54 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm.in: Call begin_transaction on the
  correct object this time

* Thu Jun 28 2012 15:48 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.1.1

* Thu Jun 28 2012 15:26 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Catalogue.pm.in, lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DataSource/Files.pm.in: Added support for using
  transactions with the database. Use the new transaction functions
  so that we are not committing changes quite so frequently

* Thu Jun 28 2012 15:08 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Catalogue.pm.in, lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DB/Schema.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Event.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Log.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Tag.pm.in,
  lib/BuzzSaw/DataSource.pm.in, lib/BuzzSaw/DataSource/Files.pm.in,
  lib/BuzzSaw/Filter.pm.in, lib/BuzzSaw/Filter/Auth.pm.in,
  lib/BuzzSaw/Filter/Kernel.pm.in, lib/BuzzSaw/Importer.pm.in,
  lib/BuzzSaw/Parser.pm.in, lib/BuzzSaw/Parser/RFC3339.pm.in:
  Enabled MooseX::Log::Log4perl for various modules. Also set
  svn:keywords on all Perl modules

* Thu Jun 28 2012 14:58 squinney@INF.ED.AC.UK
- lib/BuzzSaw/Catalogue.pm, lib/BuzzSaw/Catalogue.pm.in,
  lib/BuzzSaw/DB.pm, lib/BuzzSaw/DB.pm.in,
  lib/BuzzSaw/DB/Schema.pm, lib/BuzzSaw/DB/Schema.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Event.pm,
  lib/BuzzSaw/DB/Schema/Result/Event.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Log.pm,
  lib/BuzzSaw/DB/Schema/Result/Log.pm.in,
  lib/BuzzSaw/DB/Schema/Result/Tag.pm,
  lib/BuzzSaw/DB/Schema/Result/Tag.pm.in,
  lib/BuzzSaw/DataSource.pm, lib/BuzzSaw/DataSource.pm.in,
  lib/BuzzSaw/DataSource/Files.pm,
  lib/BuzzSaw/DataSource/Files.pm.in, lib/BuzzSaw/Filter.pm,
  lib/BuzzSaw/Filter.pm.in, lib/BuzzSaw/Filter/Auth.pm,
  lib/BuzzSaw/Filter/Auth.pm.in, lib/BuzzSaw/Filter/Kernel.pm,
  lib/BuzzSaw/Filter/Kernel.pm.in, lib/BuzzSaw/Importer.pm,
  lib/BuzzSaw/Importer.pm.in, lib/BuzzSaw/Parser.pm,
  lib/BuzzSaw/Parser.pm.in, lib/BuzzSaw/Parser/RFC3339.pm,
  lib/BuzzSaw/Parser/RFC3339.pm.in: Switched to preprocessed perl
  module files so we get the version numbers inserted at build time

* Thu Jun 28 2012 14:48 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.1.0

* Thu Jun 28 2012 14:48 squinney@INF.ED.AC.UK
- lcfg.yml, lib/BuzzSaw/Parser/RFC3339.pm: Output the whole line
  when the parsing fails

* Thu Jun 28 2012 14:44 squinney@INF.ED.AC.UK
- BuzzSaw.spec: No README right now

* Thu Jun 28 2012 14:41 squinney@INF.ED.AC.UK
- MANIFEST, MANIFEST.SKIP, META.yml.in, Makefile.PL: Added various
  files which are necessary for building the module package

* Thu Jun 28 2012 07:32 squinney@INF.ED.AC.UK
- lib/BuzzSaw/DataSource/Files.pm: simplified the way the
  uncompression of files is done as it was not reliable enough

* Wed Jun 27 2012 17:59 squinney@INF.ED.AC.UK
- BuzzSaw.spec, lcfg.yml: Added specfile

* Wed Jun 27 2012 17:35 squinney@INF.ED.AC.UK
- Build.PL.in: Added Module::Build script

* Wed Jun 27 2012 17:23 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: BuzzSaw release: 0.0.2

* Wed Jun 27 2012 17:23 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: Added buildtools project file

* Wed Jun 27 2012 17:19 squinney@INF.ED.AC.UK
- ., buzzsaw.sql, lib, lib/BuzzSaw, lib/BuzzSaw/Catalogue,
  lib/BuzzSaw/Catalogue.pm, lib/BuzzSaw/DB, lib/BuzzSaw/DB.pm,
  lib/BuzzSaw/DB/Schema, lib/BuzzSaw/DB/Schema.pm,
  lib/BuzzSaw/DB/Schema/Result,
  lib/BuzzSaw/DB/Schema/Result/Event.pm,
  lib/BuzzSaw/DB/Schema/Result/Log.pm,
  lib/BuzzSaw/DB/Schema/Result/Tag.pm, lib/BuzzSaw/DataSource,
  lib/BuzzSaw/DataSource.pm, lib/BuzzSaw/DataSource/Files.pm,
  lib/BuzzSaw/Filter, lib/BuzzSaw/Filter.pm,
  lib/BuzzSaw/Filter/Auth.pm, lib/BuzzSaw/Filter/Kernel.pm,
  lib/BuzzSaw/Importer.pm, lib/BuzzSaw/Parser,
  lib/BuzzSaw/Parser.pm, lib/BuzzSaw/Parser/RFC3339.pm: Added new
  project for parsing and filtering entries in log files


