@ECHO ON

pp -I "lib" --output="ItmReadSimple.exe" --compile --execute --compress 9 --bundle "bin\\itm_read_simple"
pp -I "lib" --output="ItmReadNocolor.exe" --compile --execute --compress 9 --bundle "bin\\itm_read_nocolor"
