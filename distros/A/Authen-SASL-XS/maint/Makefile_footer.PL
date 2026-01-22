sub postamble {
  return <<'POD';

XS.pod: XS.xs
	@echo "!!! Developers: Do not edit the XS.pod, edit the XS.xs instead. !!!"
	@echo "Make will overwrite XS.pod."
	- podselect XS.xs > XS.pod
POD
}
