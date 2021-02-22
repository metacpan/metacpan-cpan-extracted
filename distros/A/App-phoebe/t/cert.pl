# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use File::Slurper qw(write_text);

if (not -f "t/cert.pem" or not -f "t/key.pem") {
  local $/ = undef;
  my $data = <DATA>;
  my $pos = index($data, "-----BEGIN PRIVATE KEY-----");
  write_text("t/cert.pem", substr($data, 0, $pos));
  write_text("t/key.pem", substr($data, $pos));
}

1;

__DATA__
-----BEGIN CERTIFICATE-----
MIIDCzCCAfOgAwIBAgIUW+gNk6Z1w3dPB0WtWtCNInwtW/kwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MCAXDTIwMTIwMzE5NTg1M1oYDzIyOTQw
OTE4MTk1ODUzWjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCslQ7E/XcCZHoWkKhu7xs7RHy/JpuQJpbf/pbAoubo
AiyUhRMf1utmsFUDWgi81lynuQk57cizzzlqds8RJY5B1of/7uOtnmhbP/+nsBOA
TTR7/foE3hmR/15jEecsStBnJKJ7+yWEYXPk3oEffeKwKDx3C2cjPcUYBRhUZb6s
aiVMfDLKrj4UcnzlvIWdIYhLUglskpFFMsqmyEx9+cXI17F394RVZXGKPf2OoCob
G4j8AOF+cZkzIv/YyOvE2xFI8CeGHcnMG6UBnE/BY4ieAJLYKb+cjjA5BUbmbCsX
Qy3GJMYENMkYdK+xEzJy86WZ/mS9MyT2Dcpm1OHIpatNAgMBAAGjUzBRMB0GA1Ud
DgQWBBSN6uSoe6rY21xZHUbouckiwO5aoDAfBgNVHSMEGDAWgBSN6uSoe6rY21xZ
HUbouckiwO5aoDAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBZ
Q9d9TChIWfgnKpjAWVU/b2pqIf55C3OSAQij9NDHQbztUrWvH06dTtocsjdPDv+m
vx6Jqe/Ts9XdV1c+QkhPgpM310WvdzN0Y+yz9cgAPXVco1sDQwGYcqROIgz5IN3t
voxAVGWFU+Ykobp2Ag/Hjg4zGkq0KOBm8F0cPMJhYvC9LuFXNu1sDOqcPkxhA/KX
eW/XY1x+tAkTBCAotJYt0wqPo0rTK5KJZExTf4mV2lCZEJvi9vFP9Ouncui16Vke
fUypocmDBk+DKikiSfYwyTwISM/6HbnxsaIJDe+Wq5W4c5GPeYPU5+q5pwW6C4t5
xnkyAbNZ5n/obWzmAZXg
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCslQ7E/XcCZHoW
kKhu7xs7RHy/JpuQJpbf/pbAouboAiyUhRMf1utmsFUDWgi81lynuQk57cizzzlq
ds8RJY5B1of/7uOtnmhbP/+nsBOATTR7/foE3hmR/15jEecsStBnJKJ7+yWEYXPk
3oEffeKwKDx3C2cjPcUYBRhUZb6saiVMfDLKrj4UcnzlvIWdIYhLUglskpFFMsqm
yEx9+cXI17F394RVZXGKPf2OoCobG4j8AOF+cZkzIv/YyOvE2xFI8CeGHcnMG6UB
nE/BY4ieAJLYKb+cjjA5BUbmbCsXQy3GJMYENMkYdK+xEzJy86WZ/mS9MyT2Dcpm
1OHIpatNAgMBAAECggEAOhmIOlsWKJEI5PXYLliCs2YwFO37awECw+/icoGk+LBa
r7lJIevpnc15IUK7NE96K+DIMV9StO3rZ2MN/LjG9nUxncCfl4B/o1CdUaeeORBE
vgVXmTHoK9VrwjBxweCB3mdf6Bs5myJvsLoTgDWSDjnNeUo2c4/E/Xwhn7ANC9+2
T/Oimm+Z6tp4DRUUPDTt9ITZT1Jecd7UPgY55LSozXOWq45Kdmn+WUqa0oJexkiX
sCOGbY84jqBzxaRdA+IPa8QG4QaWmGPz4kACpb3mBudeYkaCFSedH6gx7raiq7Yo
v5fIKTiI7gOSwQNvTuOAeFEoJw2ULjNHDLtAYwQAJQKBgQDgfoPqG+2ADxP12UzH
Qr6OMNUAxsUf4xj8AP2qCCFWhabgi5dhT569bpSqVhsJfUP6qMAug1HvT0iqzHvl
/xKQtz/lZKafxzNg8d81y1gs7C31209YVgeY9i3g+fXq/M9tm21sqyqCAdTHApQT
kJLlRON410cr5EknOT8J8QhJUwKBgQDEzXuu2PCFFzjUfj0RqQfg/TRRpBm/ckLD
1c+9rpz5aHqHiCXpfGywbTJ8BB43RRjS7RKynso9b/LzDvfQJtHCDDBxOiy8ApSO
wpc07f8/R+ShK0FdkUzE6pKYp1Xfibprhlz8lKkcfKUq9qp3Wr1OK9lG7xRrM062
OvXSqgWE3wKBgHTV41moB0cqkbzVxvu9ZOcjyveIe3dI/evJqDsh2BfrnxomDDb8
9SSptH2iKpgZtZNy1/JdLftaS/t4SNM+mS7v8DU22PE2/yppNz4MAmv+zzyxUu4q
d/HHzcDU1oPh5yKoTZ7Mxma7BT49vUshZxIjdC+j+sqBGQFs7b4Cz8k5AoGBALfS
84dDLY4zPasF60b2qtxVxivH6yDuujwwF6YmVouEMocr/bWUufUlWjWKpyqbCO/j
70YWmfM/ASBVR9YOnHjzZ8ArRaOriVW7nv8amwNhxMViIOEkGiAItzuNeeGdxRow
W+S1eyyXpLN3yYxInnBI9t+R63GicBA5DGpk01jjAoGAKSMCDIm/x2U8Supe2bcn
UiubRcnZAt4VVi5mftjLd8ah0ykqJaHcgzmHP426ldJW1quNhkUTuEyH4778tUkY
QDfnz/a4tmi+ZK5P5oe0ECCLnvCRZNlpiJGCJT+b1qZvowrEDy+sBtbAl65JIwON
FTn8pVaxxN55fnLqWQjM2eE=
-----END PRIVATE KEY-----
