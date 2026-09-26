#  Publication is configured once in x_documentation.publish.
#
PUBLISH_TARGETS=publish_build publish_serve publish_gh publish_gh-push publish_cloudflare

.PHONY: $(PUBLISH_TARGETS)

publish_build ::
	@$(PUBLISH_PM_TARGET) publish build

publish_serve ::
	@$(PUBLISH_PM_TARGET) publish serve

publish_gh ::
	@$(PUBLISH_PM_TARGET) publish gh

publish_gh-push ::
	@$(PUBLISH_PM_TARGET) publish gh-push

publish_cloudflare ::
	@$(PUBLISH_PM_TARGET) publish cloudflare
