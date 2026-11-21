# Nomark theme - hide emphasis markers, code backticks, link brackets,
# and the <br> that breaks a table cell
pass_md+=(--cm 'emphasis_mark=sub{""}')
pass_md+=(--cm 'code_tick=sub{""}')
pass_md+=(--cm 'link_mark=sub{""}')
pass_md+=(--cm 'br_mark=sub{""}')
