--[present guests]
SELECT room_number, guest_name, check_in
FROM guests g, rooms r
WHERE g.room_id = r.room_id
	AND g.check_out IS NULL
ORDER BY room_number, guest_name

--[number of visits]
SELECT guest_name, passport_no, COUNT(*) AS number_of_visits,
	MAX(check_in) AS last_check_in
FROM guests
GROUP BY guest_name, passport_no
ORDER BY guest_name, passport_no

--[all rooms]
SELECT room_number
FROM rooms
