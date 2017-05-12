# jargon dos html techdict
for i in Linux LinuxFS UnixCmds airport areacodes country_net_codes \
	linux-howto peri_abb_and_num ports rfc_index \
	security weather ; do
	echo "Importing $i..."
	# wc -l factpacks/$i.fact
	perl -w import.pl factpacks/$i.fact
done
