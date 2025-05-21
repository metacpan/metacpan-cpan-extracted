{ pkgs ? import <nixpkgs> {} }:

with pkgs;
with perlPackages;
let
  GitWrapper = buildPerlPackage {
    pname = "Git-Wrapper";
    version = "0.048";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GE/GENEHACK/Git-Wrapper-0.048.tar.gz";
      hash = "sha256-njv/dIYZP6fkyAd0qhdRiP91px1VjswGUB3askxFGI0=";
    };
    buildInputs = [ DevelCheckBin TestDeep TestException pkgs.git ];
    propagatedBuildInputs = [ Filechdir SortVersions ];
    meta = {
      homepage = "http://genehack.github.com/Git-Wrapper/";
      description = "Wrap git(7) command-line interface";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  DistZillaPluginGitHub = buildPerlPackage {
    pname = "Dist-Zilla-Plugin-GitHub";
    version = "0.49";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Dist-Zilla-Plugin-GitHub-0.49.tar.gz";
      hash = "sha256-1wyJgKxIYmyiVI6DqtwaeInOhlws/DXF//49vkY2/EI=";
    };
    buildInputs = [ ModuleBuildTiny PathTiny TestDeep TestDeepJSON TestFatal ];
    propagatedBuildInputs = [ ClassLoad DistZilla GitWrapper IOSocketSSL JSONMaybeXS Moose NetSSLeay TryTiny ];
    meta = {
      homepage = "https://github.com/ghedo/p5-Dist-Zilla-Plugin-GitHub";
      description = "Plugins to integrate Dist::Zilla with GitHub";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  DistZillaPluginArchiveTar = buildPerlPackage {
    pname = "Dist-Zilla-Plugin-ArchiveTar";
    version = "0.03";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PL/PLICEASE/Dist-Zilla-Plugin-ArchiveTar-0.03.tar.gz";
      hash = "sha256-KI0N3tjh4EBi1lrl6lh2+vf+HJGVbBdusnJ6jJFzxJA=";
    };
    buildInputs = [ TestDeep ];
    propagatedBuildInputs = [ DistZilla Moose PathTiny namespaceautoclean ];
    meta = {
      homepage = "https://metacpan.org/pod/Dist::Zilla::Plugin::ArchiveTar";
      description = "Create dist archives using  Archive::Tar";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  perl' = perl.withPackages(p: [ p.CryptURandom p.TestException p.DistZilla DistZillaPluginGitHub DistZillaPluginArchiveTar ]);
in mkShell {
  buildInputs = [ perl' ];
}
