{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let perl' = perl.withPackages(p: [ p.CryptURandom p.TestException p.DistZilla ]);
in mkShell {
  buildInputs = [ perl' ];
}
