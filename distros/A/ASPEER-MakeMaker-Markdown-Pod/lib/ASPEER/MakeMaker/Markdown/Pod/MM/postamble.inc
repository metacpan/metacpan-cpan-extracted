#  Targets that invoke the module 
#
MARKPOD_TARGETS=


#  Always invoke targets even if no changes
#
.PHONY: doc readme $(MARKPOD_TARGETS)


#  Targets that can run without rebuiling Makefile
#
$(MARKPOD_TARGETS) ::
	@$(MARKPOD_PM_TARGET) $@

doc :: readme
	@$(MARKPOD_PM_TARGET) doc

readme ::
	@$(MARKPOD_PM_TARGET) readme
